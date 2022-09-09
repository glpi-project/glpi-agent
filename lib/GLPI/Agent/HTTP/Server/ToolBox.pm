package GLPI::Agent::HTTP::Server::ToolBox;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::Plugin";

use English qw(-no_match_vars);
use UNIVERSAL::require;
use Text::Template;
use URI::Escape;
use HTML::Entities;
use Encode qw(decode encode);
use File::stat;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Hostname;

our $VERSION = "1.1";

my %api_match = (
    version             => \&_version,
    toolbox             => \&_index,
    configuration       => \&_index,
    yaml                => \&_index,
    credentials         => \&_index,
    "toolbox.css"       => \&_file,
    "configuration.css" => \&_file,
    "inventory.css"     => \&_file,
    "results.css"       => \&_file,
    "flatpickr.min.css" => \&_file,
    "custom.css"        => \&_file,
    "mibsupport.css"    => \&_file,
    "flatpickr.js"      => \&_file,
    "logo.png"          => \&_logo,
    "config.png"        => \&_file,
    "arrow-left.png"    => \&_file,
    "favicon.ico"       => \&_favicon,
);

sub urlMatch {
    my ($self, $path) = @_;
    return 0 unless $path;
    # We will handle direct index as default toolbox page
    if ($path =~ $self->{re_index_match}) {
        $self->{request} = 'toolbox';
        return 1;
    }

    # We also need to serve file to send like for archives after a redirect
    if ($self->{_send_file}->{$path}) {
        $self->{request} = $path;
        $api_match{$path} = \&_send_file;
        return 1;
    }

    return 0 unless $path =~ $self->{re_path_match} || $path =~ m{^/(favicon\.ico)$};
    $self->{request} = $1;
    return 1;
}

sub init {
    my ($self) = @_;

    $self->SUPER::init(@_);

    # Don't do more initialization if disabled
    return if $self->disabled();

    $self->{request} = 'home';
    $self->{_pages}  = {};
    $self->{_ajax}   = {};

    # Check to fix basevardir against hostname and reset deviceid to support
    # running from different places, very important for local inventory support
    my $hostname = getHostname() || 'unknown';
    my $agent = $self->{server}->{agent};
    if ($agent && $agent->{deviceid} && $agent->{deviceid} !~ /^$hostname-/) {
        $agent->{vardir} .= "/$hostname";
        delete $agent->{storage};
        delete $agent->{deviceid};
        $agent->_handlePersistentState();
    }

    # Register all supported pages
    my ($pages_path) = $INC{module2file(__PACKAGE__)} =~ /(.*)\.pm/;
    foreach my $file (File::Glob::bsd_glob("$pages_path/*.pm")) {
        if ($OSNAME eq 'MSWin32') {
            $file =~ s{\\}{/}g;
            $pages_path =~ s{\\}{/}g;
        }

        my ($name) = $file =~ m{$pages_path/(\S+)\.pm$};
        next unless $name;

        $self->debug2("Trying to load $name ToolBox module");

        my $module = __PACKAGE__ . "::" . $name;
        $module->require();
        if ($EVAL_ERROR) {
            $self->{logger}->debug("Failed to load $name Server plugin: $EVAL_ERROR");
            next;
        }

        # Load page and prepare its support
        my $page = $module->new(toolbox => $self)
            or next;

        my $index = $page->index();
        $api_match{$index} = \&_index;

        $self->{_pages}->{$index} = $page;

        # Keep page supporting ajax for dynamic locading
        if ($page->ajax_support()) {
            $self->{_ajax}->{$index} = $page;
            $api_match{"$index/ajax"} = 1;
        }

        # Try to register events callback
        if ($page->register_events_cb() && ref($agent) =~ /Daemon/) {
            $agent->register_events_cb($page);
        }

        # Keep Results page object so we can update Results as soon as possible before it is requested
        $self->{_results} = $page
            if $name eq 'Results';
    }

    my $defaults = $self->defaults();
    $self->{index} = $self->config('url_path');
    $self->debug("Using $self->{index} as base url matching")
        if ($self->{index} ne $defaults->{url_path});
    my $regexp_api_match = join('|', keys(%api_match));
    $self->{re_path_match} = qr{^$self->{index}/($regexp_api_match)$};
    $self->{re_index_match} = qr{^$self->{index}/?$};

    $self->{htmldir} = $self->{server}->{htmldir} || '';

    # Normalize raw_edition
    $self->config('raw_edition', $self->config('raw_edition') =~ /^0|no$/i ? 0 : 1);

    # Normalize headercolor as HTML color
    if ($self->config('headercolor')) {
        if ($self->config('headercolor') !~ /^[0-9a-fA-F]{6}$/) {
            $self->debug("Wrong headercolor found");
            $self->config('headercolor', 0);
        } else {
            $self->config('headercolor', '#'.$self->config('headercolor'));
        }
    }

    # Always uses a dedicated Listener target for this plugin
    $self->{target} = GLPI::Agent::Target::Listener->new(
        logger     => $self->{logger},
        basevardir => $agent->{config}->{vardir},
    );

    # We use a dedicated YAML for some plugin configuration that can be changed online
    YAML::Tiny->require();
    if ($EVAL_ERROR) {
        $self->info("Cant't handle ToolBox online configuration without YAML::Tiny perl module");
    } else {
        $self->{yamlconfig} = -e $self->config('yaml') ?
            $self->config('yaml') : $self->confdir() . "/" . $self->config('yaml');

        # Create a default YAML when YAML file is missing
        if (! -e $self->{yamlconfig}) {
            my $yaml_tiny = YAML::Tiny->read_string(join("\n",
                "configuration:",
                "  updating_support: yes"
            ));
            $self->debug("Saving default ".$self->config('yaml')." file");
            $self->debug("YAML file: ".$self->{yamlconfig});
            $yaml_tiny->write($self->{yamlconfig});
            $self->yaml( $yaml_tiny );
        }
    }

    # Set found in confdir YAML files
    $self->scan_yaml_files();

    # Pages may require some initialization
    map { delete $_->{need_init} && $_->init() } values(%{$self->{_pages}});

    # Stil update Result page
    $self->{_results}->xml_analysis() if $self->{_results};

    $self->{_errors} = [];
    $self->{_infos}  = [];
    $self->{_yaml}   = [];

    # Still initialize important configurations
    my $yaml = $self->yaml() || {};
    my $yaml_config = $yaml->{configuration} || {};
    $self->{_session_timeout} = $yaml_config->{session_timeout} || 86400;
}

sub handle {
    my ($self, $client, $request, $clientIp) = @_;

    unless ($self->{request} && exists($api_match{$self->{request}})) {
        $self->info("unsupported api request from $clientIp");
        $client->send_error(404);
        return 404;
    }

    if ($self->{request} =~ m|^(.*)/ajax$|) {
        my $ajax = $1;
        my ($retcode, $status, $headers, $message);
        if ($ajax && $self->{_ajax}->{$ajax}) {
            ($retcode, $status, $headers, $message) =
                $self->{_ajax}->{$ajax}->ajax($request->uri()->query());
        }
        if ($retcode && $retcode == 200) {
            my $response = HTTP::Response->new(
                $retcode,
                $status,
                HTTP::Headers->new(%{$headers}),
                $message
            );
            $client->send_response($response);
            return $retcode;
        }
        $self->info("unsupported ajax request from $clientIp");
        $client->send_error(404);
        return 404;
    }

    return &{$api_match{$self->{request}}}( $self, $client, $request, $clientIp );
}

sub ajax_support {
    return 0;
}

sub register_events_cb {
    return 0;
}

sub log_prefix {
    return "[toolbox plugin] ";
}

sub config_file {
    return "toolbox-plugin.cfg";
}

sub defaults {
    return {
        disabled    => "yes",
        url_path    => "/toolbox",
        port        => 0,
        yaml        => "toolbox.yaml",
        logo        => "toolbox/logo.png",
        addnavlink  => undef,
        headercolor => undef,
        raw_edition => "no",
    };
}

sub yaml_config_specs {
    my ($self, $yaml_config) = @_;

    return {
        updating_support => {
            category    => "Toolbox plugin configuration",
            type        => $self->isyes($yaml_config->{updating_support}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{updating_support}),
            text        => "Configuration update authorized",
        },
        yaml => {
            category    => "Toolbox plugin configuration",
            type        => "readonly",
            value       => $self->config('yaml'),
            text        => "YAML configuration file (default YAML file)",
        },
        raw_edition => {
            category    => "YAML edition",
            type        => "readonly",
            value       => $self->yesno($self->config('raw_edition')),
            text        => "Raw YAML edition authorization",
        },
        yaml_navbar => {
            category    => "Navigation bar",
            type        => $self->isyes($yaml_config->{updating_support}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{yaml_navbar}),
            text        => "Show Raw YAML navigation",
            navbar      => "Raw YAML".($self->config('raw_edition') ? " edition" : ""),
            link        => "yaml",
            index       => 100, # index in navbar
        },
        default_page => {
            category    => "Navigation",
            type        => $self->isyes($yaml_config->{updating_support}) ? "option" : "readonly",
            value       => $yaml_config->{'default_page'} || (
                $self->isyes($yaml_config->{'updating_support'}) ? "" : "[default]"),
            options     => '', # Must be set later after all pages has been loaded
            text        => "Default page",
            tips        => "Defaults to first page of the options list"
        },
        headercolor => {
            category    => "ToolBox User Interface",
            type        => "readonly",
            value       => length($self->config('headercolor')) ?
                $self->config('headercolor') : "default from CSS",
            text        => "Header background color",
        },
        logo => {
            category    => "ToolBox User Interface",
            type        => "readonly",
            value       => $self->config('logo'),
            text        => "Logo",
        },
        languages => {
            category    => "ToolBox User Interface",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "text" : "readonly",
            value       => $yaml_config->{'languages'} || 'en|fr',
            text        => "Supported languages",
            tips        => "list of languages separated by pipes\nfirst language is used as default\n(default=en|fr)"
        },
        language => {
            category    => "ToolBox User Interface",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "option" : "readonly",
            value       => $yaml_config->{'language'} || (
                $self->isyes($yaml_config->{'updating_support'}) ? "" : "[default]"),
            options     => [ split('[|]', $yaml_config->{'languages'} || 'en|fr') ],
            text        => "Language",
            tips        => "Defaults to first language of the supported languages"
        },
        session_timeout => {
            category    => "Toolbox plugin configuration",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "number" : "readonly",
            value       => $yaml_config->{'session_timeout'} || 86400,
            text        => "Session timeout",
            tips        => "Defaults to 86400 seconds (1 day)"
        },
    };
}

sub _version {
    my ($self, $client, $clientIp) = @_;

    my $response = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new( 'Content-Type' => 'text/plain' ),
        $VERSION
    );

    $client->send_response($response);

    return 200;
}

sub yaml {
    my ($self, $yaml) = @_;
    # Handle yaml in parent for pages
    if ($self->{toolbox}) {
        return $self->{toolbox}->yaml($yaml);
    } elsif ($yaml) {
        if (ref($yaml) eq 'HASH') {
            foreach my $key (keys(%{$yaml})) {
                $self->{_yaml}->[0]->{$key} = $yaml->{$key};
            }
        } elsif (ref($yaml)) {
            $self->{_yaml} = $yaml;
        } elsif (ref($self->{_yaml}) eq 'YAML::Tiny') {
            return $self->{_yaml}->[0]->{$yaml};
        }
    }
    return $self->{_yaml}->[0];
}

sub invalidate_yaml {
    my ($self) = @_;
    delete $self->{_yaml_bases};
    $self->yaml([0]);
}

sub read_yaml {
    my ($self) = @_;

    return $self->{toolbox}->read_yaml()
        if $self->{toolbox};

    $self->{_yaml_loaded_time} = {};
    my $mtime = stat($self->{yamlconfig})->mtime;
    $self->debug("Loading default YAML from ".$self->config('yaml'));
    $self->debug2("YAML file: ".$self->{yamlconfig});
    my $yaml = YAML::Tiny->read($self->{yamlconfig});
    unless ($yaml) {
        $self->error("Failed to load ".$self->config('yaml').": $EVAL_ERROR");
        return;
    }
    $yaml = { configuration => {} } unless ref($yaml) eq 'YAML::Tiny' && $yaml->[0];
    $self->yaml($yaml);
    $self->{_yaml_loaded_time}->{$self->{yamlconfig}} = $mtime;

    # Now we have loaded default conf we can check other YAML to load
    $self->{_yaml_files} = {};
    if ($self->{_yaml_bases}) {
        foreach my $base (keys(%{$self->{_yaml_bases}})) {
            my $file = $self->{_yaml_bases}->{$base}
                or next;
            push @{$self->{_yaml_files}->{$file}}, $base;
        }
    } else {
        my @config_specs = $self->_config_specs($self->yaml()->{configuration} || {});
        foreach my $config_specs (@config_specs) {
            foreach my $key (keys(%{$config_specs})) {
                my $spec = $config_specs->{$key};
                my $base = $spec->{yaml_base}
                    or next;
                my $file = $spec->{value}
                    or next;
                next if $file eq '[default]';
                $self->{_yaml_bases}->{$base} = $file;
                push @{$self->{_yaml_files}->{$file}}, $base;
            }
        }
    }

    foreach my $file (keys(%{$self->{_yaml_files}})) {
        next unless @{$self->{_yaml_files}->{$file}};
        my $yaml_file = $self->confdir() . "/" . $file;
        $self->debug("Reading YAML from $file");
        $self->debug2("YAML file: $yaml_file");
        my $yaml = YAML::Tiny->read($yaml_file);
        unless ($yaml && $yaml->[0]) {
            $self->error("Failed to read $file: $EVAL_ERROR");
            return;
        }
        foreach my $base (@{$self->{_yaml_files}->{$file}}) {
            next unless $yaml->[0]->{$base};
            my $mtime = stat($yaml_file)->mtime;
            $self->debug("Loading $base from $file");
            $self->yaml({ $base => $yaml->[0]->{$base} });
            $self->{_yaml_loaded_time}->{$yaml_file} = $mtime;
        }
    }

    return 1;
}

sub reload_yaml_on_change {
    my ($self) = @_;

    return unless $self->{_yaml_loaded_time};

    my $reload_needed = 0;
    foreach my $file (keys(%{$self->{_yaml_loaded_time}})) {
        my $mtime = stat($file)->mtime;
        if ($mtime > $self->{_yaml_loaded_time}->{$file}) {
            $reload_needed++;
            $self->debug("Reloading YAML files on $file update");
            last;
        }
    }

    if ($reload_needed) {
        $self->read_yaml();
        # Also reset Results if possible
        if ($self->{_results}) {
            $self->{_results}->reset();
        }
    }
}

sub write_yaml {
    my ($self, $backup) = @_;

    # Handle yaml in parent for pages
    return $self->{toolbox}->write_yaml($backup)
        if ($self->{toolbox});

    # Only save if needed
    my %need = $self->save_needed()
        or return;

    my $yaml = $self->yaml();

    # Prepare hash for default YAML
    my %yaml_default = map { $_ => $yaml->{$_} } keys(%{$yaml});

    foreach my $file (keys(%{$self->{_yaml_files}})) {
        next unless @{$self->{_yaml_files}->{$file}};
        my $found = 0;
        my %yaml_base = ();
        foreach my $base (@{$self->{_yaml_files}->{$file}}) {
            if ($yaml->{$base}) {
                $self->debug("Keeping $base for $file");
                $yaml_base{$base} = $yaml->{$base};
            } else {
                $yaml_base{$base} = {};
            }
            # Cleanup default YAML at the same time
            delete $yaml_default{$base};
            # Mark file to be saved
            if ($need{$base}) {
                $found++;
                delete $need{$base};
            }
        }
        if ($need{all} || $found) {
            my $yaml_file = $self->confdir() . "/" . $file;
            my $yaml_tiny = YAML::Tiny->read($yaml_file);
            unless ($yaml_tiny) {
                $self->error("Can't update YAML file: $file");
                next;
            }
            # Update read YAML with our bases
            foreach my $base (keys(%yaml_base)) {
                $yaml_tiny->[0]->{$base} = $yaml_base{$base};
            }
            if ($backup) {
                $self->info("Making backup of YAML file: $file");
                my ($ext) = $file =~ m|\.(ya?ml)$|;
                my $backup_dir = $self->confdir() . "/backup";
                # Be sure a backup folder exists
                mkdir $backup_dir unless -d $backup_dir;
                $yaml_file = $backup_dir . "/" . $file;
                $yaml_file =~ s/\.ya?ml$//;
                $yaml_file .= "$backup.$ext";
            } else {
                $self->debug("Saving YAML file: $file");
            }
            $self->debug2("YAML file: $yaml_file");
            $yaml_tiny->write($yaml_file)
                or $self->error("Failed to save $file: $EVAL_ERROR");
        }
    }

    if (keys(%need)) {
        my $yaml_file = $self->{yamlconfig};
        my $yaml_tiny = YAML::Tiny->read($yaml_file);
        if ($yaml_tiny) {
            if ($backup) {
                $self->info("Making backup of YAML file: ".$self->config('yaml'));
                my ($ext) = $self->config('yaml') =~ m|\.(ya?ml)$|;
                $yaml_file = $self->confdir() . "/backup/" . $self->config('yaml');
                $yaml_file =~ s/\.ya?ml$//;
                $yaml_file .= "$backup.$ext";
            } else {
                $self->debug("Saving default YAML file: ".$self->config('yaml'));
            }
            $self->debug2("YAML file: $yaml_file");
            # Update read YAML with our kept bases
            foreach my $base (keys(%yaml_default)) {
                $yaml_tiny->[0]->{$base} = $yaml_default{$base};
            }
            $yaml_tiny->write($yaml_file)
                or $self->error("Failed to save ".$self->config('yaml').": $EVAL_ERROR");
        } elsif ($backup) {
            $self->error("Can't make backup of YAML file: ".$self->config('yaml'));
        } else {
            $self->error("Can't update YAML file: ".$self->config('yaml'));
        }
    }
}

sub yaml_files {
    my ($self) = @_;
    # Handle yaml_files in parent for pages
    return $self->{toolbox} ?
        $self->{toolbox}->yaml_files() : $self->{_scanned_yamls} ;
}

sub scan_yaml_files {
    my ($self) = @_;

    $self->{_scanned_yamls} = [ $self->config('yaml') ];
    foreach my $file (File::Glob::bsd_glob($self->confdir()."/*.y{a,}ml")) {
        my ($config) = $file =~ m|/([^/]+)$|;
        push @{$self->{_scanned_yamls}}, $config
            unless $config eq $self->config('yaml');
    }
}

sub need_save {
    my ($self, $save) = @_;
    # Handle need_save in parent for pages
    if ($self->{toolbox}) {
        $self->{toolbox}->need_save($save);
    } elsif (defined($save)) {
        $self->{_need_save}->{$save} = 1;
    } else {
        $self->{_need_save}->{all} = 1;
    }
}

sub save_needed {
    my ($self, $test) = @_;
    # Handle save_needed in parent for pages
    if ($self->{toolbox}) {
        return $self->{toolbox}->save_needed($test);
    } elsif ($test) {
        return $self->{_need_save} && $self->{_need_save}->{$test};
    }
    return unless $self->{_need_save};
    my %need = %{$self->{_need_save}};
    $self->{_need_save} = {};
    return %need;
}

sub _index {
    my ($self, $client, $request, $clientIp) = @_;

    YAML::Tiny->require();
    if ($EVAL_ERROR) {
        $self->error("Cant't load needed YAML::Tiny perl module");
        $client->send_error(500);
        return 500;
    }

    # Retrieve client current session
    my $session = $self->_get_session($request);

    my $form;
    $self->reset_errors();
    $self->reset_infos();
    $self->reset_edit();

    if ($request->method() eq 'POST') {
        $form = $self->_get_form($request->content());

        if ($form->{'raw-yaml'}) {
            if ($self->config('raw_edition')) {
                $self->yaml( YAML::Tiny->read_string($form->{'raw-yaml'}) );
                $self->need_save();
            }
            undef $form;
        }
    } elsif ($request->method() eq 'GET' && $request->uri()->query()) {
        $form = $self->_get_form($request->uri()->query());
        $form->{form} = $self->{request};
    } else {
        # Reset form knowledge
        $self->form({});
    }

    # Generally, we read YAML from files unless it just has been submitted
    unless ($self->yaml() || $self->read_yaml()) {
        $self->error("Failed to load YAML");
        $client->send_error(500);
        return 500;
    }

    # Handle POST or GET with query cases
    $self->submit_form()
        if $form ;

    # Send early redirect
    if (my $redirect = delete $self->{redirect}) {
        my $referer = $request->header('Referer');
        my $base_path = $self->config('url_path')."/".$self->{request};
        $referer =~ s/$base_path$//;
        my $ret = $self->send_redirect($referer.$self->config('url_path')."/".$redirect, $client);
        return $ret;
    }

    # Read again YAML if it has been invalidated by a new configuration
    unless ($self->yaml() || $self->read_yaml()) {
        $self->error("Failed to reload YAML");
        $client->send_error(500);
        return 500;
    }

    # We may also need to reload YAML if any YAML file has been updated
    $self->reload_yaml_on_change();

    # Saving YAML may be requested after a POST
    $self->write_yaml();

    # Rescan for available YAML file in confdir on update from configuration page
    $self->scan_yaml_files()
        if ($form && $self->{request} eq 'configuration');

    # If the submitted form requires to download a file, send a redirect as response
    if ($form && $form->{send_file}) {
        my $referer = $request->header('Referer');
        $form->{send_file} =~ s|^\./||;
        my $request = $self->config('url_path')."/".$self->{request}."/files/".$form->{send_file};
        $self->{_send_file}->{$request} = $form->{send_file};
        my $url = $referer."/files/".$form->{send_file};
        return $self->_send_file_redirect($client, $url);
    }

    my $yaml_config = $self->yaml()->{configuration} || {};
    my @config_specs = $self->_config_specs($yaml_config);
    my $default_page = $self->_fix_default_page_options(\@config_specs);
    $self->{request} = $yaml_config->{default_page} || $default_page
        if $self->{request} eq 'toolbox';
    my @navbar = ();
    my @addnavlink = split(/\s*\|\s*/, $self->config('addnavlink') || '|');

    # Still load template, but after default page has eventually been selected
    my ($ret, $template) = $self->_template();
    if ($ret != 200) {
        $client->send_error($ret);
        return $ret;
    }

    # Compute navigation bar elements with ordering on index
    my %navbar = ();
    foreach my $config_specs (@config_specs) {
        foreach my $key (keys(%{$config_specs})) {
            my $navbar = delete $config_specs->{$key}->{navbar}
                or next;
            my $link = delete $config_specs->{$key}->{link}
                or next;
            next unless $self->isyes($config_specs->{$key}->{value});
            my $index = delete $config_specs->{$key}->{index} || 0;
            push @{$navbar{$index}}, [ $navbar, $link ];
        }
    }
    foreach my $index (sort { $a <=> $b } keys(%navbar)) {
        push @navbar, @{$navbar{$index}};
    }

    my @languages = split('[|]', $yaml_config->{'languages'} || 'en|fr');

    # Re-encode any still provided entries
    foreach my $key (keys(%{$form})) {
        $form->{$key} = encode('utf-8', encode_entities($form->{$key}));
    }

    my $hash = {
        request         => $self->{request} || $default_page,
        url_path        => $self->config('url_path'),
        update_support  => $self->isyes($yaml_config->{updating_support}),
        raw_edition     => $self->isyes($self->config('raw_edition')),
        errors          => $self->errors(),
        infos           => $self->infos(),
        edit            => $self->edit(),
        form            => $form,
        headercolor     => $self->config('headercolor'),
        logo            => $self->config('logo'),
        navbar          => \@navbar,
        addnavlink      => \@addnavlink,
        template_path   => $self->{htmldir}."/toolbox",
        lang            => $yaml_config->{'language'} || $languages[0],
        default_lang    => $languages[0],
    };

    # Keep self ref in hash for template include support
    $hash->{hash} = \$hash;

    # Update template hash regarding the supported page
    my $page = $self->{_pages}->{$self->{request}};
    $page->update_template_hash($hash)
        if $page;

    # For configuration, transmit pages configurations category & type
    if ($self->{request} eq 'configuration') {
        foreach my $config_specs (@config_specs) {
            foreach my $key (keys(%{$config_specs})) {
                my $category = delete $config_specs->{$key}->{category};
                $hash->{configuration_specs}->{$category}->{$key} = $config_specs->{$key};
            }
        }
        $hash->{title} = "ToolBox plugin Configuration";
    } elsif ($self->{request} eq 'yaml' && $self->isyes($yaml_config->{'yaml_navbar'})) {
        my $yaml_tiny = YAML::Tiny->new($self->yaml());
        $hash->{rawyaml} = encode('UTF-8', encode_entities($yaml_tiny->write_string()));
        $hash->{title} = $hash->{raw_edition} ? "Raw YAML edition" : "Raw YAML";
    }

    my $html = $template->fill_in(HASH => $hash);
    unless ($html) {
        $self->error("template failure: $Text::Template::ERROR");
        $client->send_error(500);
        return 500;
    }

    my $headers  = HTTP::Headers->new(
        'Content-Type'          => 'text/html',
        'Keep-Alive'            => 'timeout=1, max=8',
    );

    my $cookie = $self->_get_cookie();
    $headers->header( 'Set-Cookie' => $cookie) if $cookie;

    my $response = HTTP::Response->new(
        200,
        'OK',
        $headers,
        $html
    );

    $client->send_response($response);

    # Update session infos
    $self->debug2(
        $session->info(
            "remoteip: $clientIp",
            "request: ".$self->config('url_path')."/".($self->{request} || $default_page),
            "ua: ".($request->header('User-Agent') || "n/a"),
        )
    );

    return 200;
}

sub send_redirect {
    my ($self, $where, $client) = @_;

    if ($self->{toolbox}) {
        $self->{toolbox}->{redirect} = $where;
    } elsif ($client) {
        # A content is necessary to have the redirect sent immediatly
        $client->send_redirect($where, 302, "toolbox redirect");
    }

    return 302;
}

sub _file {
    my ($self, $client) = @_;

    $client->send_file_response($self->{htmldir}."/toolbox/".$self->{request});

    return 200;
}

sub _send_file_redirect {
    my ($self, $client, $file_url) = @_;

    $client->send_redirect($file_url, 302);

    return 302;
}

sub _send_file {
    my ($self, $client) = @_;

    my $file_url = $self->{request};
    my $file_path = $self->{_send_file} && $self->{_send_file}->{$file_url};

    unless ($file_path && -e $file_path) {
        $self->error("send file failure for $file_url");
        $client->send_error(404);
        return 404;
    }

    $client->send_file_response($file_path);

    # Finally delete the file
    unlink $file_path;

    return 200;
}

sub _logo {
    my ($self, $client) = @_;

    my $logo = $self->config('logo');
    # Try alternative if logo is not found
    $logo = "$self->{htmldir}/$logo"
        unless $logo && -e $logo;
    $logo = "$self->{htmldir}/".$self->defaults()->{logo}
        unless $logo && -e $logo;

    $client->send_file_response($logo);

    return 200;
}

sub _favicon {
    my ($self, $client) = @_;

    $client->send_file_response("$self->{htmldir}/favicon.ico");

    return 200;
}

sub _template {
    my ($self) = @_;

    my $file = "toolbox/".$self->{request}.".tpl";
    unless ( -e $self->{htmldir}."/$file") {
        $self->error("$file template not found in ".$self->{htmldir});
        return 404;
    }

    my $template = Text::Template->new(
        TYPE => 'FILE',
        SOURCE => $self->{htmldir}."/toolbox/index.tpl"
    );
    if (!$template) {
        $self->error("$file template access failed: $Text::Template::ERROR");
        return 500;
    }

    return 200, $template;
}

sub supported_method {
    my ($self, $method) = @_;

    return 1 if $method eq 'GET' || $method eq 'POST';

    $self->error("invalid request type: $method");

    return 0;
}

sub _get_form {
    my ($self, $data) = @_;
    my $form;
    foreach my $param (split('&', $data)) {
        my ($name, $value) = split('=', $param);
        next unless $name;
        $name =~ s/\+/ /g;
        $name = decode_entities(decode('UTF-8', uri_unescape($name)));
        $form->{$name} = defined($value) ? $value : '';
        next unless $value;
        $value =~ s/\+/ /g;
        $form->{$name} = decode_entities(decode('UTF-8', uri_unescape($value)));
    }
    return $self->{_form} = $form;
}

sub form {
    my ($self, $form) = @_;
    $self->{_form} = $form if (defined($form));
    return $self->{_form};
}

sub reset_infos {
    my ($self) = @_;
    $self->{_infos} = [];
}

sub infos {
    my ($self, $info) = @_;
    return $self->{_infos} unless $info;
    if ($self->{toolbox}) {
        $self->{toolbox}->infos($info);
    } else {
        push @{$self->{_infos}}, $info;
    }
}

sub reset_errors {
    my ($self) = @_;
    $self->{_errors} = [];
}

sub errors {
    my ($self, $error) = @_;
    return $self->{_errors} unless $error;
    # Handle errors in parent for pages
    if ($self->{toolbox}) {
        $self->{toolbox}->errors($error);
    } else {
        push @{$self->{_errors}}, $error;
    }
}

sub edit {
    my ($self, $edit) = @_;

    # Handle edit in parent for pages
    return $self->{toolbox}->edit($edit)
        if ($self->{toolbox});

    return unless $self->{session};

    return $self->{session}->kept('edit') || ''
        unless defined($edit);

    $self->{session}->keep('edit', $edit);
}

sub reset_edit {
    my ($self) = @_;

    # Handle reset_edit in parent for pages
    return $self->{toolbox}->reset_edit()
        if $self->{toolbox};

    return unless $self->{session};

    $self->{session}->forget('edit');
}

sub config {
    my ($self, $name, $value) = @_;

    # Handle config in parent for pages
    return $self->{toolbox}->config($name, $value)
        if $self->{toolbox};

    $self->{$name} = $value if (defined($value));
    return $self->{$name};
}

sub yesno {
    my ($self, $value) = @_;
    return $value && $value =~ /^1|yes$/i ? "yes" : "no";
}

sub isyes {
    my ($self, $value) = @_;
    return $value && $value =~ /^1|yes$/i ? 1 : 0;
}

sub page {
    my ($self, $page) = @_;
    # Handle yaml_files in parent for pages
    return $self->{toolbox} ?
        $self->{toolbox}->page($page) : $self->{_pages}->{$page || $self->{request}} ;
}

sub submit_form {
    my ($self) = @_;

    my $form = $self->form()
        or return;

    foreach my $key (keys(%{$form})) {
        $self->debug2("Submitted form: '".encode('UTF-8',$key)."' => '".encode('UTF-8',$form->{$key})."'");
    }

    # Handle all supported POST cases
    $self->_configuration();

    # Handle form on supported page
    return unless $form->{form} && $self->{_pages}->{$form->{form}};
    $self->{_pages}->{$form->{form}}->handle_form($form);
}

sub _fix_default_page_options {
    my ($self, $config_specs) = @_;

    my %enabled = ();

    foreach my $list (@{$config_specs}) {
        foreach my $config (%{$list}) {
            my $page = $list->{$config};
            next unless $page->{navbar} && $page->{link} && defined($page->{index});
            next unless $self->isyes($page->{value});
            $enabled{$config} = $page;
        }
    }

    my $default_page_options = [
        map { [ $_->{navbar} => $_->{link} ] }
            sort { $a->{index} <=> $b->{index} }
                values(%enabled)
    ];
    $config_specs->[0]->{default_page}->{options} = $default_page_options;

    return $default_page_options->[0]->[1];
}

sub _config_specs {
    my ($self, $yaml_config) = @_;
    return $self->yaml_config_specs($yaml_config),
        map { $_->yaml_config_specs($yaml_config) } values(%{$self->{_pages}});
}

sub _configuration {
    my ($self) = @_;

    my $form = $self->form()
        or return;

    return unless $form->{form} && $form->{form} =~ /^configuration$/;

    my $yaml = $self->yaml() || {};

    if ($form->{'submit/update'}) {
        my $yaml_config = $yaml->{configuration} || {};
        my $invalidated = 0;

        my @config_specs = $self->_config_specs($yaml_config);
        foreach my $config_specs (@config_specs) {
            foreach my $key (keys(%{$config_specs})) {
                my $current = $yaml_config->{$key} || "";
                my $value = $form->{$key} || "";
                my $type = $config_specs->{$key}->{'type'} || "";
                next if $type eq 'readonly';
                $value = $self->yesno($value)
                    if $type eq "bool";
                if ($current && $value eq "[default]" && $type eq "option") {
                    $self->debug2("Resetting $key to default");
                    delete $yaml_config->{$key};
                    $self->need_save("configuration");
                    # Make YAML invalid if a YAML file configuration has been changed
                    $invalidated++ if $config_specs->{$key}->{'yaml_base'};
                } elsif ($current ne $value) {
                    $self->debug2("$key set to: $value");
                    $yaml_config->{$key} = $value;
                    $self->need_save("configuration");
                    # Make YAML invalid if a YAML file configuration has been changed
                    $invalidated++ if $config_specs->{$key}->{'yaml_base'};
                }
            }
        }

        # Fix and save configuration if needed
        $self->yaml({ configuration => $yaml_config })
            if $self->save_needed("configuration");
        $self->write_yaml();

        # Finally check if we need to invalidate currently loaded YAML
        $self->invalidate_yaml() if $invalidated;

    } elsif ($form->{'submit/backup'}) {
        my @t = localtime();
        $self->need_save();
        my $backup_timestamp = sprintf("-%04d-%02d-%02d-%02dh%02d",
                $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1]);
        $self->write_yaml($backup_timestamp);
    }
}

sub update_results {
    my ($self) = @_;

    # Handle API in parent if necessary
    return $self->{toolbox}->update_results()
        if $self->{toolbox};

    $self->{_results}->xml_analysis()
        if $self->{_results};
}

sub _get_session {
    my ($self, $request) = @_;

    my $timeout = $self->{_session_timeout} || 86400;

    my @cookies = $request->header('Cookie');
    my ($sid) = map { /^sid=(.*)$/ } grep { /^sid=/ } @cookies;

    $self->{session} = $self->{target}->session(
        remoteid    => $sid || '',
        timeout     => $timeout,
    );
}

sub _get_cookie {
    my ($self) = @_;

    return unless $self->{session};

    # Return string to be sent to client as "Set-Cookie" header
    return "sid=".$self->{session}->sid()."; httpOnly; sameSite=Strict; Path=".$self->config('url_path');
}

sub _session_data {
    my ($self, $data, $value) = @_;

    return unless $self->{session};

    if (defined($value)) {
        $self->{session}->set($data, $value);
    } else {
        return $self->{session}->get($data);
    }
}

sub timer_event {
    my ($self) = @_;
    return $self->{target} && $self->{target}->keep_sessions();
}

sub store_in_session {
    my ($self, $key, $value) = @_;

    # Handle API in parent if necessary
    return $self->{toolbox}->store_in_session($key, $value)
        if $self->{toolbox};

    $self->_session_data($key, $value);
}

sub get_from_session {
    my ($self, $key) = @_;

    # Handle API in parent if necessary
    return $self->{toolbox}->get_from_session($key)
        if $self->{toolbox};

    return $self->_session_data($key);
}

sub delete_in_session {
    my ($self, $key) = @_;

    # Handle API in parent if necessary
    return $self->{toolbox}->delete_in_session($key)
        if $self->{toolbox};

    return unless $self->{session};

    $self->{session}->delete($key);
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Server::ToolBox - An embedded HTTP
server plugin to handle some tools

=head1 DESCRIPTION

This is a server plugin to listen on some advanced tools requests.

It listens on port 62354 by default.

=head1 CONFIGURATION

=over

=item disabled         C<yes> by default

=item url_path         C</toolbox> by default

=item port             C<0> by default to use default one

=item yaml             Toolbox configuration YAML file,  C<toolbox.yml> by default

=item logo             <toolbox/logo.png> by default

=item addnavlink       Could be set to add a private navigation link, not set by default

=item headercolor      Could be set to change header color, not set by default

=item raw_edition      C<no> by default. Set it yo "yes" to permit YAML edition tool.

=back

Defaults can be overrided in C<toolbox-plugin.cfg> file or better in the
C<toolbox-plugin.local> if included from C<toolbox-plugin.cfg> (the default).
