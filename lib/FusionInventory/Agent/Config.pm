package FusionInventory::Agent::Config;

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Spec;
use Cwd qw(abs_path);
use Getopt::Long;
use UNIVERSAL::require;

use FusionInventory::Agent::Version;

use FusionInventory::Agent::Tools;

my $default = {
    'additional-content'      => undef,
    'backend-collect-timeout' => 180,
    'ca-cert-dir'             => undef,
    'ca-cert-file'            => undef,
    'color'                   => undef,
    'conf-reload-interval'    => 0,
    'debug'                   => undef,
    'delaytime'               => 3600,
    'force'                   => undef,
    'html'                    => undef,
    'lazy'                    => undef,
    'local'                   => undef,
    'logger'                  => 'Stderr',
    'logfile'                 => undef,
    'logfacility'             => 'LOG_USER',
    'logfile-maxsize'         => undef,
    'no-category'             => [],
    'no-httpd'                => undef,
    'no-ssl-check'            => undef,
    'no-compression'          => undef,
    'no-task'                 => [],
    'no-p2p'                  => undef,
    'password'                => undef,
    'proxy'                   => undef,
    'httpd-ip'                => undef,
    'httpd-port'              => 62354,
    'httpd-trust'             => [],
    'listen'                  => undef,
    'scan-homedirs'           => undef,
    'scan-profiles'           => undef,
    'server'                  => undef,
    'tag'                     => undef,
    'tasks'                   => undef,
    'timeout'                 => 180,
    'user'                    => undef,
    'vardir'                  => undef,
    # deprecated options
    'stdout'                  => undef,
};

my $deprecated = {
    'stdout' => {
        message => 'use --local - option instead',
        new     => { 'local' => '-' }
    },
};

my $confReloadIntervalMinValue = 60;

sub new {
    my ($class, %params) = @_;

    my $self = {
        '_confdir' => undef, # SYSCONFDIR replaced here from Makefile
        '_options' => $params{options} // {},
    };
    bless $self, $class;
    $self->_loadDefaults();

    # Reset confdir to be absolute confdir if found to be relative. This avoid
    # wrong path usage for http server plugin in the case perl current path is changing.
    # This can be the case while running agent as daemon into an administrator console under win32
    $self->{_confdir} = abs_path(File::Spec->rel2abs($self->{_confdir}))
        if $self->{_confdir} =~ m|^\.+/|;

    $self->_loadFromBackend($params{options}->{'conf-file'}, $params{options}->{config});

    $self->_loadUserParams($params{options});

    $self->{vardir} = $params{vardir};

    # To also keep vardir during reload
    $self->{_options}->{vardir} = $params{vardir};

    $self->_checkContent();

    return $self;
}

sub reload {
    my ($self) = @_;

    $self->_loadDefaults;

    $self->_loadFromBackend($self->{'conf-file'}, $self->{config});

    # Reload script options and vardir
    $self->_loadUserParams($self->{_options});

    $self->_checkContent();

    # delaytime must not be used after a reload
    $self->{delaytime} = 0;
}

sub _loadFromBackend {
    my ($self, $confFile, $config) = @_;

    my $backend =
        $confFile            ? 'file'      :
        $config              ? $config     :
        $OSNAME eq 'MSWin32' ? 'registry'  :
                               'file';

    SWITCH: {
        if ($backend eq 'registry') {
            die "Config: Unavailable configuration backend\n"
                unless $OSNAME eq 'MSWin32';
            $self->_loadFromRegistry();
            last SWITCH;
        }

        if ($backend eq 'file') {
            # Handle loadedConfs to avoid loops
            $self->{loadedConfs} = {};
            $self->loadFromFile({
                file => $confFile
            });
            delete $self->{loadedConfs};
            last SWITCH;
        }

        if ($backend eq 'none') {
            last SWITCH;
        }

        die "Config: Unknown configuration backend '$backend'\n";
    }
}

sub _loadDefaults {
    my ($self) = @_;

    foreach my $key (keys %$default) {
        $self->{$key} = $default->{$key};
    }

    # No need to reset confdir at each call
    return if $self->{_confdir} && -d $self->{_confdir};

    # Set absolute confdir from default if replaced by Makefile otherwise search
    # from current path, mostly useful while running from source
    $self->{_confdir} = abs_path(File::Spec->rel2abs(
        $self->{_confdir} || first { -d $_ } qw{ ./etc  ../etc ../../etc }
    ));
}

sub _loadFromRegistry {
    my ($self) = @_;

    my $Registry;
    Win32::TieRegistry->require();
    Win32::TieRegistry->import(
        Delimiter   => '/',
        ArrayValues => 0,
        TiedRef     => \$Registry
    );

    my $machKey = $Registry->Open('LMachine', {
        Access => Win32::TieRegistry::KEY_READ()
    }) or die "Config: Can't open HKEY_LOCAL_MACHINE key: $EXTENDED_OS_ERROR\n";

    my $provider = $FusionInventory::Agent::Version::PROVIDER;
    my $settings = $machKey->{"SOFTWARE/$provider-Agent"};

    foreach my $rawKey (keys %$settings) {
        next unless $rawKey =~ /^\/(\S+)/;
        my $key = lc($1);
        my $val = $settings->{$rawKey};
        # Remove the quotes
        $val =~ s/\s+$//;
        $val =~ s/^'(.*)'$/$1/;
        $val =~ s/^"(.*)"$/$1/;

        if (exists $default->{$key}) {
            $self->{$key} = $val;
        } else {
            warn "Config: unknown configuration directive $key\n";
        }
    }
}

sub confdir {
    my ($self) = @_;

    return $self->{_confdir};
}

sub loadFromFile {
    my ($self, $params) = @_;
    my $file = $params->{file} ?
        $params->{file} : $self->{_confdir} . '/agent.cfg';

    if ($file) {
        die "Config: non-existing file $file\n" unless -f $file;
        die "Config: non-readable file $file\n" unless -r $file;
    } else {
        die "Config: no configuration file\n";
    }

    # Don't reload conf if still loaded avoiding loops due to include directive
    if ($self->{loadedConfs}->{$file}) {
        warn "Config: $file configuration file still loaded\n"
            if $self->{logger} && ucfirst($self->{logger}) eq 'Stderr';
        return;
    }
    $self->{loadedConfs}->{$file} = 1;

    my $handle;
    if (!open $handle, '<', $file) {
        warn "Config: Failed to open $file: $ERRNO\n";
        return;
    }

    while (my $line = <$handle>) {
        if ($line =~ /^\s*([\w-]+)\s*=\s*(.*)$/) {
            my $key = $1;
            my $val = $2;

            # Cleanup value from ending spaces
            $val =~ s/\s+$//;

            # Extract value from quotes or clean any comment including preceding spaces
            if ($val =~ /^(['"])([^\1]*)\1/) {
                my ($quote, $extract) = ( $1, $2 );
                $val =~ s/\s*#.+$//;
                warn "Config: We may have been confused for $key quoted value, our extracted value: '$extract'\n"
                    if ($val ne "$quote$extract$quote");
                $val = $extract ;
            } else {
                $val =~ s/\s*#.+$//;
            }

            if ($params->{defaults} && exists $params->{defaults}->{$key}) {
                $self->{$key} = $val;
            } elsif (!$params->{defaults} && exists $default->{$key}) {
                $self->{$key} = $val;
            } elsif (lc($key) eq 'include') {
                $self->_includeDirective($val, $file);
            } else {
                warn "Config: unknown configuration directive $key\n";
            }
        } elsif ($line =~ /^\s*include\s+(.+)$/i) {
            my $include = $1;
            if ($include =~ /^(['"])([^\1]*)\1/) {
                my ($quote, $extract) = ( $1, $2 );
                $include =~ s/\s*#.+$//;
                warn "Config: We may have been confused for include quoted path, our extracted path: '$extract'\n"
                    if ($include ne "$quote$extract$quote");
                $include = $extract ;
            } else {
                $include =~ s/\s*#.+$//;
            }
            $self->_includeDirective($include, $file, $params->{defaults});
        }
    }
    close $handle;
}

sub _includeDirective {
    my ($self, $include, $currentconfig, $defaults) = @_;

    # Make include path absolute, relatively to current file basedir
    unless (File::Spec->file_name_is_absolute($include)) {
        my @path = File::Spec->splitpath($currentconfig);
        $path[2] = $include;
        $include = File::Spec->catpath(@path);
    }
    # abs_path makes call die under windows if file doen't exist, so we need to eval it
    eval {
        $include = abs_path($include);
    };
    return unless $include;

    if (-d $include) {
        foreach my $cfg ( sort glob("$include/*.cfg") ) {
            # Skip missing or non-readable file
            next unless -f $cfg && -r $cfg;
            $self->loadFromFile({ file => $cfg, defaults => $defaults });
        }
    } elsif ( -f $include && -r $include ) {
        $self->loadFromFile({ file => $include, defaults => $defaults });
    }
}

sub _loadUserParams {
    my ($self, $params) = @_;

    foreach my $key (keys %$params) {
        $self->{$key} = $params->{$key};
    }
}

sub _checkContent {
    my ($self) = @_;

    # check for deprecated options
    foreach my $old (keys %$deprecated) {
        next unless defined $self->{$old};

        next if $old =~ /^no-/ and !$self->{$old};

        my $handler = $deprecated->{$old};

        # notify user of deprecation
        warn "Config: the '$old' option is deprecated, $handler->{message}\n";

        # transfer the value to the new option, if possible
        if ($handler->{new}) {
            if (ref $handler->{new} eq 'HASH') {
                # old boolean option replaced by new non-boolean options
                foreach my $key (keys %{$handler->{new}}) {
                    my $value = $handler->{new}->{$key};
                    if ($value =~ /^\+(\S+)/) {
                        # multiple values: add it to exiting one
                        $self->{$key} = $self->{$key} ?
                            $self->{$key} . ',' . $1 : $1;
                    } else {
                        # unique value: replace exiting value
                        $self->{$key} = $value;
                    }
                }
            } elsif (ref $handler->{new} eq 'ARRAY') {
                # old boolean option replaced by new boolean options
                foreach my $new (@{$handler->{new}}) {
                    $self->{$new} = $self->{$old};
                }
            } else {
                # old non-boolean option replaced by new option
                $self->{$handler->{new}} = $self->{$old};
            }
        }

        # avoid cluttering configuration
        delete $self->{$old};
    }

    # a logfile options implies a file logger backend
    if ($self->{logfile}) {
        $self->{logger} .= ',File';
    }

    # ca-cert-file and ca-cert-dir are antagonists
    if ($self->{'ca-cert-file'} && $self->{'ca-cert-dir'}) {
        die "Config: use either 'ca-cert-file' or 'ca-cert-dir' option, not both\n";
    }

    # logger backend without a logfile isn't enoguh
    if ($self->{'logger'} =~ /file/i && ! $self->{'logfile'}) {
        die "Config: usage of 'file' logger backend makes 'logfile' option mandatory\n";
    }

    # multi-values options, the default separator is a ','
    foreach my $option (qw/
            logger
            local
            server
            httpd-trust
            no-task
            no-category
            tasks
            /) {

        # Check if defined AND SCALAR
        # to avoid split a ARRAY ref or HASH ref...
        if ($self->{$option} && ref($self->{$option}) eq '') {
            $self->{$option} = [split(/,/, $self->{$option})];
        } else {
            $self->{$option} = [];
        }
    }

    # files location
    $self->{'ca-cert-file'} =
        File::Spec->rel2abs($self->{'ca-cert-file'}) if $self->{'ca-cert-file'};
    $self->{'ca-cert-dir'} =
        File::Spec->rel2abs($self->{'ca-cert-dir'}) if $self->{'ca-cert-dir'};
    $self->{'logfile'} =
        File::Spec->rel2abs($self->{'logfile'}) if $self->{'logfile'};
    $self->{'vardir'} =
        File::Spec->rel2abs($self->{'vardir'}) if $self->{'vardir'};

    # conf-reload-interval option
    # If value is less than the required minimum, we force it to that
    # minimum because it's useless to reload the config so often and,
    # furthermore, it can cause a loss of performance
    if ($self->{'conf-reload-interval'} != 0) {
        if ($self->{'conf-reload-interval'} < 0) {
            $self->{'conf-reload-interval'} = 0;
        } elsif ($self->{'conf-reload-interval'} < $confReloadIntervalMinValue) {
            $self->{'conf-reload-interval'} = $confReloadIntervalMinValue;
        }
    }
}

sub hasFilledParam {
    my ($self, $paramName) = @_;

    return unless defined($self->{$paramName});

    return unless ref($self->{$paramName}) eq 'ARRAY';

    return scalar(@{$self->{$paramName}}) > 0;
}

sub logger {
    my ($self) = @_;

    return {
        map { $_ => $self->{$_} }
            qw/debug logger logfacility logfile logfile-maxsize color/
    };
}

sub getTargets {
    my ($self, %params) = @_;

    my @targets = ();

    # create target list
    if ($self->{local}) {
        FusionInventory::Agent::Target::Local->require();
        FusionInventory::Agent::Target::Local->reset();
        foreach my $path (@{$self->{local}}) {
            push @targets,
                FusionInventory::Agent::Target::Local->new(
                    logger     => $params{logger},
                    delaytime  => $self->{delaytime},
                    basevardir => $params{vardir},
                    path       => $path,
                    html       => $self->{html},
                );
        }
    }

    if ($self->{server}) {
        FusionInventory::Agent::Target::Server->require();
        FusionInventory::Agent::Target::Scheduler->require();
        FusionInventory::Agent::Target::Server->reset();
        FusionInventory::Agent::Target::Scheduler->reset();
        foreach my $url (@{$self->{server}}) {
            my $server = FusionInventory::Agent::Target::Server->new(
                logger     => $params{logger},
                delaytime  => $self->{delaytime},
                basevardir => $params{vardir},
                url        => $url,
                tag        => $self->{tag},
            );

            # Also setup one Scheduler target for each target, actually
            # it only used by Maintenance task to cleanup storage from
            # expired files
            # Schedule it to run every 2 minutes max by default
            my $scheduler = FusionInventory::Agent::Target::Scheduler->new(
                logger      => $params{logger},
                delaytime   => $self->{delaytime} ? 60 : 0,
                maxDelay    => 120,
                basevardir  => $params{vardir},
                storage     => $server->getStorage(),
            );
            push @targets, $server, $scheduler;
        }
    }

    # Only add listener target if no other target has been defined and
    # httpd daemon is enabled. And anyway only one listener should be enabled
    if ($self->{listen} && !@targets && !$self->{'no-httpd'}) {
        FusionInventory::Agent::Target::Listener->require();
        if ($EVAL_ERROR) {
            die "Config: Failure while loading FusionInventory::Agent::Target::Listener: $EVAL_ERROR\n";
        }
        push @targets,
            FusionInventory::Agent::Target::Listener->new(
                logger     => $params{logger},
                delaytime  => $self->{delaytime},
                basevardir => $params{vardir},
            );
    }

    return \@targets;
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Config - Agent configuration

=head1 DESCRIPTION

This is the object used by the agent to store its configuration.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<options>

additional options override.

=back

=head2 logger()

Get logger only configuration.
