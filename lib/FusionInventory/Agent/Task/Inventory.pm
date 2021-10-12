package FusionInventory::Agent::Task::Inventory;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task';

use Config;
use English qw(-no_match_vars);
use UNIVERSAL::require;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Inventory;

use FusionInventory::Agent::Task::Inventory::Version;

# Preload Module base class
use FusionInventory::Agent::Task::Inventory::Module;

our $VERSION = FusionInventory::Agent::Task::Inventory::Version::VERSION;

sub isEnabled {
    my ($self, $contact) = @_;

    # always enabled for local target
    return 1 if $self->{target}->isType('local');

    if ($self->{target}->isGlpiServer()) {
        # Store any inventory params
        my $tasks = $contact->get("tasks");
        if (ref($tasks) eq 'HASH' && ref($tasks->{inventory}) eq 'HASH' && ref($tasks->{inventory}->{params}) eq 'ARRAY') {
            if (@{$tasks->{inventory}->{params}}) {
                # Add a GLPI client to each param with a category and a use property
                # and if related category is not disabled
                my %disabled = map { $_ => 1 } @{$self->{config}->{'no-category'}};
                my @params;
                my $cant_load_glpi_client = 0;
                foreach my $param (@{$tasks->{inventory}->{params}}) {
                    my @validated;
                    if (!$param->{category} || $disabled{$param->{category}}) {
                    } elsif ($param->{params_id}) {
                        # Here we must handle the case of remotely triggered events
                        my @categories = map { trimWhitespace($_) } split(/,+/, $param->{category});
                        foreach my $category (@categories) {
                            my @ids = map { trimWhitespace($_) } split(/,+/, $param->{params_id});
                            foreach my $params_id (@ids) {
                                my $this_param = {
                                    use         => $param->{use},
                                    category    => $category,
                                    params_id   => $params_id,
                                };
                                my $use = $param->{"use[$params_id]"};
                                $this_param->{use} = [ map { trimWhitespace($_) } split(/,+/, $use) ] if $use;

                                # Setup GLPI server client for get_params requests
                                if ($this_param->{use}) {
                                    FusionInventory::Agent::HTTP::Client::GLPI->require();
                                    if ($EVAL_ERROR) {
                                        $self->{logger}->error("Can't load GLPI client API to handle get_params")
                                            unless $cant_load_glpi_client++;
                                    } else {
                                        my $config = $self->{config};
                                        $this_param->{_glpi_client} = FusionInventory::Agent::HTTP::Client::GLPI->new(
                                            logger       => $self->{logger},
                                            user         => $config->{user},
                                            password     => $config->{password},
                                            proxy        => $config->{proxy},
                                            ca_cert_file => $config->{'ca-cert-file'},
                                            ca_cert_dir  => $config->{'ca-cert-dir'},
                                            no_ssl_check => $config->{'no-ssl-check'},
                                            no_compress  => $config->{'no-compression'},
                                            agentid      => $self->{agentid},
                                        );
                                        $this_param->{_glpi_url} = $self->{target}->getUrl();
                                        push @validated, $this_param;
                                    }
                                }
                            }
                        }
                    } elsif ($param->{use}) {
                        push @validated, $param;
                    }
                    if (@validated) {
                        push @params, @validated;
                    } else {
                        my $debug = join(",", map { "$_=".($param->{$_}//"") } keys(%{$param}));
                        $self->{logger}->debug("Skipping invalid params: $debug")
                    }
                }
                $self->{params} = \@params if @params;
            }
        }

        # If we are here, this still means the task has not been disabled in GLPI server
        return 1;
    } else {
        my $content = $contact->getContent();
        if (!$content || !$content->{RESPONSE} || $content->{RESPONSE} ne 'SEND') {
            if ($self->{config}->{force}) {
                $self->{logger}->debug("Inventory task execution not requested, but execution forced");
            } else {
                $self->{logger}->debug("Inventory task execution not requested");
                return;
            }
        }

        $self->{registry} = [ $contact->getOptionsInfoByName('REGISTRY') ];
    }
    return 1;
}

sub run {
    my ($self, %params) = @_;

    if ( $REAL_USER_ID != 0 ) {
        $self->{logger}->warning(
            "You should execute this task as super-user"
        );
    }

    $self->{modules} = {};

    my $tag = $self->{config}->{'tag'};

    my $inventory = FusionInventory::Agent::Inventory->new(
        statedir => $self->{target}->getStorage()->getDirectory(),
        deviceid => $self->{deviceid},
        logger   => $self->{logger},
        tag      => $tag
    );

    my $event = $self->event;
    my $name = $event && $event->{name} ? $event->{name} : "inventory";
    $self->{logger}->info("New $name from ".$inventory->getDeviceId().
        " for $self->{target}->{id}".
        ( (defined($tag) && length($tag)) ? " (tag=$tag)" : "" ));

    # Set inventory as remote if running remote inventory like from wmi task
    $inventory->setRemote($self->getRemote()) if $self->getRemote();

    if (not $ENV{PATH}) {
        # set a minimal PATH if none is set (#1129, #1747)
        $ENV{PATH} =
            '/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin';
        $self->{logger}->debug(
            "PATH is not set, using $ENV{PATH} as default"
        );
    }

    # Set credentials if set
    $inventory->credentials($self->{credentials}) if $self->{credentials};

    $self->{inventory} = $inventory;
    $self->{disabled}  = {
        map { $_ => 1 } @{$self->{config}->{'no-category'}}
    };

    # Support inventory event
    if ($event && !$self->setupEvent()) {
        $self->{logger}->info("Skipping Inventory task event on ".$self->{target}->id());
        return;
    }

    $self->_initModulesList();
    $self->_feedInventory();

    # Tell perl modules hash can now be cleaned from memory
    delete $self->{modules};

    return $self->submit();
}

sub setupEvent {
    my ($self) = @_;

    my $event = $self->resetEvent();
    if ($self->{target}->isType('server') && !$self->{target}->isGlpiServer()) {
        $self->{logger}->debug($self->{target}->id().": server target for inventory events need to be a GLPI server");
        return;
    }

    unless ($event->{partial}) {
        $self->{logger}->debug("Only support partial inventory events for Inventory task");
        return;
    }

    # Support event with category defined
    if ($event->{category}) {
        my %keep = map { lc($_) => 1 } grep { ! $self->{disabled}->{$_} } split(/,+/, $event->{category});
        unless (keys(%keep)) {
            $self->{logger}->debug("Nothing to inventory on partial inventory event");
            return;
        }
        my @categories = $self->getCategories();
        my $valid = 0;
        foreach my $category (keys(%keep)) {
            if (any { $_ eq $category } @categories) {
                $valid = 1;
            } else {
                $self->{logger}->debug("Unknown category on partial inventory event: $category");
            }
        }
        unless ($valid) {
            $self->{logger}->debug("Invalid partial inventory event with no supported category");
            return;
        }
        my $cached = $self->cachedata();
        if ($cached) {
            $self->{inventory}->mergeContent($cached);
            $self->keepcache(0);
        } else {
            # If no data has been cached from previous partial inventory run, we
            # also need to get hardware and bios category to keep them in cache
            $keep{hardware} = 1;
            $keep{bios} = 1;
            $self->keepcache(1);
        }
        foreach my $category (@categories) {
            $self->{disabled}->{$category} = 1 unless $keep{$category};
        }
    } else {
        $self->{logger}->debug("No category property on partial inventory event");
        return;
    }

    # Setup partial inventory
    return $self->{partial} = 1;
}

sub submit {
    my ($self) = @_;

    my $config    = $self->{config};
    my $inventory = $self->{inventory};

    # Keep cached data for next partial inventory
    if ($self->{partial} && $self->keepcache() && !$self->cachedata()) {
        my $content = $inventory->getContent();
        my $keep = {
            map { $_ => $content->{$_} } grep { $content->{$_} } qw(BIOS HARDWARE)
        };
        $self->cachedata($keep);
    }

    if ($self->{target}->isType('local')) {
        my $path   = $self->{target}->getPath();
        my $format = $self->{partial} ? "json" : $self->{target}->{format};
        my ($file, $handle);

        SWITCH: {
            if ($path eq '-') {
                $handle = \*STDOUT;
                last SWITCH;
            }

            if (-d $path) {
                $file =
                    $path . "/" . $inventory->getDeviceId() .
                    ($format eq 'xml' ? '.xml' : '.html');
                $file = $path . "/" . $self->{agentid} . ".json"
                    if $format eq 'json';
                last SWITCH;
            }

            $file = $path;
        }

        if ($file) {
            if (Win32::Unicode::File->require()) {
                $handle = Win32::Unicode::File->new('w', $file);
            } else {
                open($handle, '>', $file)
                    or die "Can't write to $file: $ERRNO\n";
            }
            $self->{logger}->error("Can't write to $file: $ERRNO")
                unless $handle;
        }

        binmode $handle, ':encoding(UTF-8)'
            unless $format eq "json";

        $self->_printInventory(
            handle    => $handle,
            format    => $format
        );

        if ($file) {
            $self->{logger}->info("Inventory saved in $file");
            close $handle;
        }

    } elsif ($self->{target}->isGlpiServer()) {

        return $self->{logger}->error("Can't load GLPI client API")
            unless FusionInventory::Agent::HTTP::Client::GLPI->require();

        my $client = FusionInventory::Agent::HTTP::Client::GLPI->new(
            logger       => $self->{logger},
            user         => $config->{user},
            password     => $config->{password},
            proxy        => $config->{proxy},
            ca_cert_file => $config->{'ca-cert-file'},
            ca_cert_dir  => $config->{'ca-cert-dir'},
            no_ssl_check => $config->{'no-ssl-check'},
            no_compress  => $config->{'no-compression'},
            agentid      => $self->{agentid},
        );

        return $self->{logger}->error("Can't load GLPI Protocol Inventory library")
            unless GLPI::Agent::Protocol::Inventory->require();

        my $message = GLPI::Agent::Protocol::Inventory->new(
            logger      => $self->{logger},
            deviceid    => $inventory->getDeviceId(),
            content     => $inventory->getContent(),
            partial     => $self->{partial},
            itemtype    => "Computer",
        );

        # Support json file on additional-content with json output
        $message->mergeContent(content => delete $self->{_json_merge})
            if $self->{_json_merge};

        # Normalize some strings to expected type (integer)
        $message->normalize();

        my $response = $client->send(
            url     => $self->{target}->getUrl(),
            message => $message
        );
        return unless $response;

        return $response;

    } elsif ($self->{target}->isType('server')) {

        return $self->{logger}->error("Can't load OCS client API")
            unless FusionInventory::Agent::HTTP::Client::OCS->require();

        my $client = FusionInventory::Agent::HTTP::Client::OCS->new(
            logger       => $self->{logger},
            user         => $config->{user},
            password     => $config->{password},
            proxy        => $config->{proxy},
            ca_cert_file => $config->{'ca-cert-file'},
            ca_cert_dir  => $config->{'ca-cert-dir'},
            no_ssl_check => $config->{'no-ssl-check'},
            no_compress  => $config->{'no-compression'},
            agentid      => $self->{agentid},
        );

        return $self->{logger}->error("Can't load Inventory XML Query API")
            unless FusionInventory::Agent::XML::Query::Inventory->require();

        my $message = FusionInventory::Agent::XML::Query::Inventory->new(
            deviceid => $inventory->getDeviceId(),
            content  => $inventory->getContent()
        );

        my $response = $client->send(
            url     => $self->{target}->getUrl(),
            message => $message
        );

        return unless $response;

    } elsif ($self->{target}->isType('listener')) {

        return $self->{logger}->error("Can't load Inventory XML Query API")
            unless FusionInventory::Agent::XML::Query::Inventory->require();

        my $query = FusionInventory::Agent::XML::Query::Inventory->new(
            deviceid => $inventory->getDeviceId(),
            content  => $inventory->getContent()
        );

        # Store inventory XML with the listener target
        $self->{target}->inventory_xml($query->getContent());
    }

}

sub getCategories {
    my ($self) = @_;

    my @modules = $self->getModules('Inventory');
    die "no inventory module found\n" if !@modules;

    my %categories = ();

    foreach my $module (sort @modules) {
        # Just skip Version package as not an inventory package module
        # Also skip Module as not a real module but the base class for any module
        next if $module =~ /FusionInventory::Agent::Task::Inventory::(Version|Module)$/;

        $module->require();
        next if $EVAL_ERROR;

        # Check module category
        if (defined(*{$module."::category"})) {
            no strict 'refs'; ## no critic (ProhibitNoStrict)
            my $category = &{$module."::category"}();
            $categories{$category} = 1;
        }

        # Check module other_categories listing used category in doInventory()
        if (defined(*{$module."::other_categories"})) {
            no strict 'refs'; ## no critic (ProhibitNoStrict)
            map { $categories{$_} = 1 } &{$module."::other_categories"}();
        }
    }

    return keys(%categories);
}

sub _initModulesList {
    my ($self) = @_;

    my $logger = $self->{logger};
    my $config = $self->{config};

    my @modules = $self->getModules('Inventory');
    die "no inventory module found\n" if !@modules;

    # Select isEnabled function to test
    my $isEnabledFunction = "isEnabled" ;
    $isEnabledFunction .= "ForRemote" if (($self->getRemote() // '') eq 'wmi');

    # first pass: compute all relevant modules
    foreach my $module (sort @modules) {
        # compute parent module:
        my @components = split('::', $module);
        my $parent = @components > 5 ?
            join('::', @components[0 .. $#components -1]) : '';

        # Just skip Version package as not an inventory package module
        # Also skip Module as not a real module but the base class for any module
        if ($module =~ /FusionInventory::Agent::Task::Inventory::(Version|Module)$/) {
            $self->{modules}->{$module}->{enabled} = 0;
            next;
        }

        # skip if parent is not allowed
        if ($parent && !$self->{modules}->{$parent}->{enabled}) {
            $logger->debug2("  $module disabled: implicit dependency $parent not enabled");
            $self->{modules}->{$module}->{enabled} = 0;
            next;
        }

        $module->require();
        if ($EVAL_ERROR) {
            $logger->debug("module $module disabled: failure to load ($EVAL_ERROR)");
            $self->{modules}->{$module}->{enabled} = 0;
            next;
        }

        # Check module category and disabled it if category found in 'no_category' param
        if (defined(*{$module."::category"})) {
            no strict 'refs'; ## no critic (ProhibitNoStrict)
            my $category = &{$module."::category"}();
            if ($category && $self->{disabled}->{$category}) {
                $logger->debug2("module $module disabled: '$category' category disabled");
                $self->{modules}->{$module}->{enabled} = 0;
                next;
            }
        }

        # Simulate tested function inheritance as we test a module, not a class
        unless (defined(*{$module."::".$isEnabledFunction})) {
            no strict 'refs'; ## no critic (ProhibitNoStrict)
            *{$module."::".$isEnabledFunction} =
                \&{"FusionInventory::Agent::Task::Inventory::Module::$isEnabledFunction"};
        }

        my $enabled = runFunction(
            module   => $module,
            function => $isEnabledFunction,
            logger => $logger,
            timeout  => $config->{'backend-collect-timeout'},
            params => {
                datadir       => $self->{datadir},
                logger        => $self->{logger},
                registry      => $self->{registry},
                scan_homedirs => $config->{'scan-homedirs'},
                scan_profiles => $config->{'scan-profiles'},
            }
        );
        if (!$enabled) {
            $logger->debug2("module $module disabled");
            $self->{modules}->{$module}->{enabled} = 0;
            next;
        }

        $self->{modules}->{$module}->{enabled} = 1;
        $self->{modules}->{$module}->{done}    = 0;
        $self->{modules}->{$module}->{used}    = 0;

        no strict 'refs'; ## no critic (ProhibitNoStrict)
        $self->{modules}->{$module}->{runAfter} = [
            $parent ? $parent : (),
            ${$module . '::runAfter'} ? @${$module . '::runAfter'} : (),
            ${$module . '::runAfterIfEnabled'} ? @${$module . '::runAfterIfEnabled'} : ()
        ];
        $self->{modules}->{$module}->{runAfterIfEnabled} = {
            map { $_ => 1 }
                ${$module . '::runAfterIfEnabled'} ? @${$module . '::runAfterIfEnabled'} : ()
        };
    }

    # second pass: disable fallback modules
    foreach my $module (@modules) {
        ## no critic (ProhibitProlongedStrictureOverride)
        no strict 'refs'; ## no critic (ProhibitNoStrict)

        # skip modules already disabled
        next unless $self->{modules}->{$module}->{enabled};
        # skip non-fallback modules
        next unless ${$module . '::runMeIfTheseChecksFailed'};

        my $failed;

        foreach my $other_module (@${$module . '::runMeIfTheseChecksFailed'}) {
            if ($self->{modules}->{$other_module}->{enabled}) {
                $failed = $other_module;
                last;
            }
        }

        if ($failed) {
            $self->{modules}->{$module}->{enabled} = 0;
            $logger->debug("module $module disabled because of $failed");
        }
    }
}

sub _runModule {
    my ($self, $module) = @_;

    my $logger = $self->{logger};

    return if $self->{modules}->{$module}->{done};

    $self->{modules}->{$module}->{used} = 1; # lock the module

    # ensure all needed modules have been executed first
    foreach my $other_module (@{$self->{modules}->{$module}->{runAfter}}) {
        die "module $other_module, needed before $module, not found"
            if !$self->{modules}->{$other_module};

        if (!$self->{modules}->{$other_module}->{enabled}) {
            if ($self->{modules}->{$module}->{runAfterIfEnabled}->{$other_module}) {
                # soft dependency: run current module without required one
                next;
            } else {
                # hard dependency: abort current module execution
                die "module $other_module, needed before $module, not enabled";
            }
        }

        die "circular dependency between $module and $other_module"
            if $self->{modules}->{$other_module}->{used};

        $self->_runModule($other_module);
    }

    $logger->debug("Running $module");

    runFunction(
        module   => $module,
        function => "doInventory",
        logger => $logger,
        timeout  => $self->{config}->{'backend-collect-timeout'},
        params => {
            datadir       => $self->{datadir},
            inventory     => $self->{inventory},
            no_category   => $self->{disabled},
            logger        => $self->{logger},
            registry      => $self->{registry},
            params        => $self->{params},
            scan_homedirs => $self->{config}->{'scan-homedirs'},
            scan_profiles => $self->{config}->{'scan-profiles'},
        }
    );
    $self->{modules}->{$module}->{done} = 1;
    $self->{modules}->{$module}->{used} = 0; # unlock the module
}

sub _feedInventory {
    my ($self) = @_;

    my $begin = time();
    my @modules =
        grep { $self->{modules}->{$_}->{enabled} }
        keys %{$self->{modules}};

    foreach my $module (sort @modules) {
        $self->_runModule($module);
    }

    # Inject additional content if required
    $self->_injectContent();

    # Execution time
    my $versionprovider = $self->{inventory}->getSection("VERSIONPROVIDER");
    $versionprovider->{ETIME} = time() - $begin
        if $versionprovider;

    # Don't compute checksum on partial inventory
    $self->{inventory}->computeChecksum() unless $self->{partial} || $self->{nochecksum};
}

sub _injectContent {
    my ($self) = @_;

    my $file = $self->{config}->{'additional-content'}
        or return;

    return unless -f $file;

    $self->{logger}->debug(
        "importing $file file content to the inventory"
    );

    my $content;
    if ($file =~ /\.xml$/) {
        eval {
            my $tree = XML::TreePP->new()->parsefile($file);
            $content = $tree->{REQUEST}->{CONTENT};
        };
    } elsif ($file =~ /\.json$/) {
        GLPI::Agent::Protocol::Message->require();
        my $json = GLPI::Agent::Protocol::Message->new(
            message => {},
            file    => $file,
        );
        if ($json) {
            $self->{_json_merge} = $json->get('content');
            return;
        }
    } else {
        die "unknown file type $file";
    }

    if (!$content) {
        $self->{logger}->error("no suitable content found");
        return;
    }

    $self->{inventory}->mergeContent($content);
}

sub _printInventory {
    my ($self, %params) = @_;

    SWITCH: {
        if ($params{format} eq 'xml') {

            my $tpp = XML::TreePP->new(
                indent          => 2,
                utf8_flag       => 1,
                output_encoding => 'UTF-8'
            );
            print {$params{handle}} $tpp->write({
                REQUEST => {
                    CONTENT  => $self->{inventory}->getContent(),
                    DEVICEID => $self->{inventory}->getDeviceId(),
                    QUERY    => "INVENTORY",
                }
            });

            last SWITCH;
        }

        if ($params{format} eq 'html') {
            Text::Template->require();
            my $template = Text::Template->new(
                TYPE => 'FILE', SOURCE => "$self->{datadir}/html/inventory.tpl"
            );

             my $hash = {
                version  => $FusionInventory::Agent::Version::VERSION,
                deviceid => $self->{inventory}->getDeviceId(),
                data     => $self->{inventory}->getContent(),
                fields   => $self->{inventory}->getFields()
            };

            print {$params{handle}} $template->fill_in(HASH => $hash);

            last SWITCH;
        }

        if ($params{format} eq 'json') {
            die "Can't load GLPI Protocol Inventory library: $EVAL_ERROR\n"
                unless GLPI::Agent::Protocol::Inventory->require();
            my $inventory = GLPI::Agent::Protocol::Inventory->new(
                logger      => $self->{logger},
                deviceid    => $self->{inventory}->getDeviceId(),
                content     => $self->{inventory}->getContent(),
                partial     => $self->{partial},
                itemtype    => "Computer",
            );

            # Support json file on additional-content with json output
            $inventory->mergeContent(content => delete $self->{_json_merge})
                if $self->{_json_merge};

            # Normalize some strings to expected type (integer)
            $inventory->normalize();

            print {$params{handle}} $inventory->getContent();

            last SWITCH;
        }

        die "unknown format $params{format}\n";
    }
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Task::Inventory - Inventory task for FusionInventory

=head1 DESCRIPTION

This task extract various hardware and software information on the agent host.
