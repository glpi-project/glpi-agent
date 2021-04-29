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

    $self->{logger}->info("New inventory from ".$inventory->getDeviceId()." for $self->{target}->{id}".
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

    $self->{inventory} = $inventory;
    $self->{disabled}  = {
        map { $_ => 1 } @{$self->{config}->{'no-category'}}
    };

    $self->_initModulesList();
    $self->_feedInventory();

    # Tell perl modules hash can now be cleaned from memory
    delete $self->{modules};

    return $self->submit();
}

sub submit {
    my ($self) = @_;

    my $config    = $self->{config};
    my $inventory = $self->{inventory};

    if ($self->{target}->isType('local')) {
        my $path   = $self->{target}->getPath();
        my $format = $self->{target}->{format};
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
            message     => $inventory->getContent(),
        );

        my $response = $client->send(
            url     => $self->{target}->getUrl(),
            message => $message
        );
        return unless $response;

        while ($response->status eq "pending") {
            sleep $response->expiration;
            $response = $client->send(
                url         => $self->{target}->getUrl(),
                requestid   => $response->id(),
            );
        }

        $inventory->saveLastState();

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
        $inventory->saveLastState();

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
    $isEnabledFunction .= "ForRemote" if $self->getRemote();

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
            if ($category && $disabled->{$category}) {
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
    my $versionprovider = $inventory->getSection("VERSIONPROVIDER");
    $versionprovider->[0]->{ETIME} = time() - $begin
        if $versionprovider && @{$versionprovider};

    $inventory->computeChecksum();
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
    SWITCH: {
        if ($file =~ /\.xml$/) {
            eval {
                my $tree = XML::TreePP->new()->parsefile($file);
                $content = $tree->{REQUEST}->{CONTENT};
            };
            last SWITCH;
        }
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
                message     => {
                    content => $self->{inventory}->getContent(),
                }
            );
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
