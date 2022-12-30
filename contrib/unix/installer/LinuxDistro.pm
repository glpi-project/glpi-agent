package
    LinuxDistro;

use strict;
use warnings;

BEGIN {
    $INC{"LinuxDistro.pm"} = __FILE__;
}

# This array contains four items for each distribution:
# - release file
# - distribution name,
# - regex to get the version
# - template to get the full name
# - packaging class in RpmDistro, DebDistro
my @distributions = (
    # vmware-release contains something like "VMware ESX Server 3" or "VMware ESX 4.0 (Kandinsky)"
    [ '/etc/vmware-release',    'VMWare',                     '([\d.]+)',         '%s' ],

    [ '/etc/arch-release',      'ArchLinux',                  '(.*)',             'ArchLinux' ],

    [ '/etc/debian_version',    'Debian',                     '(.*)',             'Debian GNU/Linux %s',    'DebDistro' ],

    # fedora-release contains something like "Fedora release 9 (Sulphur)"
    [ '/etc/fedora-release',    'Fedora',                     'release ([\d.]+)', '%s',                     'RpmDistro' ],

    [ '/etc/gentoo-release',    'Gentoo',                     '(.*)',             'Gentoo Linux %s' ],

    # knoppix_version contains something like "3.2 2003-04-15".
    # Note: several 3.2 releases can be made, with different dates, so we need to keep the date suffix
    [ '/etc/knoppix_version',   'Knoppix',                    '(.*)',             'Knoppix GNU/Linux %s' ],

    # mandriva-release contains something like "Mandriva Linux release 2010.1 (Official) for x86_64"
    [ '/etc/mandriva-release',  'Mandriva',                   'release ([\d.]+)', '%s'],

    # mandrake-release contains something like "Mandrakelinux release 10.1 (Community) for i586"
    [ '/etc/mandrake-release',  'Mandrake',                   'release ([\d.]+)', '%s'],

    # oracle-release contains something like "Oracle Linux Server release 6.3"
    [ '/etc/oracle-release',    'Oracle Linux Server',        'release ([\d.]+)', '%s',                     'RpmDistro' ],

    # rocky-release contains something like "Rocky Linux release 8.5 (Green Obsidian)
    [ '/etc/rocky-release',     'Rocky Linux',                'release ([\d.]+)', '%s',                     'RpmDistro' ],

    # centos-release contains something like "CentOS Linux release 6.0 (Final)
    [ '/etc/centos-release',    'CentOS',                     'release ([\d.]+)', '%s',                     'RpmDistro' ],

    # redhat-release contains something like "Red Hat Enterprise Linux Server release 5 (Tikanga)"
    [ '/etc/redhat-release',    'RedHat',                     'release ([\d.]+)', '%s',                     'RpmDistro' ],

    [ '/etc/slackware-version', 'Slackware',                  'Slackware (.*)',   '%s' ],

    # SuSE-release contains something like "SUSE Linux Enterprise Server 11 (x86_64)"
    # Note: it may contain several extra lines
    [ '/etc/SuSE-release',      'SuSE',                       '([\d.]+)',         '%s',                     'RpmDistro' ],

    # trustix-release contains something like "Trustix Secure Linux release 2.0 (Cloud)"
    [ '/etc/trustix-release',   'Trustix',                    'release ([\d.]+)', '%s' ],

    # Fallback
    [ '/etc/issue',             'Unknown Linux distribution', '([\d.]+)'        , '%s' ],
);

# When /etc/os-release is present, the selected class will be the one for which
# the found name matches the given regexp
my %classes = (
    DebDistro   => qr/debian|ubuntu/i,
    RpmDistro   => qr/red\s?hat|centos|fedora|opensuse/i,
);

sub new {
    my ($class, $options) = @_;

    my $self = {
        _bin        => "/usr/bin/glpi-agent",
        _silent     => delete $options->{silent}  // 0,
        _verbose    => delete $options->{verbose} // 0,
        _service    => delete $options->{service}, # checked later against cron
        _cron       => delete $options->{cron}    // 0,
        _runnow     => delete $options->{runnow}  // 0,
        _dont_ask   => delete $options->{"no-question"} // 0,
        _type       => delete $options->{type},
        _user_proxy => delete $options->{"use-current-user-proxy"} // 0,
        _options    => $options,
        _cleanpkg   => 1,
        _skip       => {},
        _downgrade  => 0,
    };
    bless $self, $class;

    my $distro = delete $options->{distro};
    my $force  = delete $options->{force};
    my $snap   = delete $options->{snap} // 0;

    my ($name, $version, $release);
    ($name, $version, $release, $class) = $self->_getDistro();
    if ($force) {
        $name = $distro if defined($distro);
        $version = "unknown version" unless defined($version);
        $release = "unknown distro" unless defined($distro);
        ($class) = grep { $name =~ $classes{$_} } keys(%classes);
        $self->allowDowngrade();
    }
    $self->{_name}    = $name;
    $self->{_version} = $version;
    $self->{_release} = $release;

    $class = "SnapInstall" if $snap;

    die "Not supported linux distribution\n"
        unless defined($name) && defined($version) && defined($release);
    die "Unsupported $release linux distribution ($name:$version)\n"
        unless defined($class);

    bless $self, $class;

    $self->verbose("Running on linux distro: $release : $name : $version...");

    # service is mandatory when set with cron option
    if (!defined($self->{_service})) {
        $self->{_service} = $self->{_cron} ? 0 : 1;
    } elsif ($self->{_cron}) {
        $self->info("Disabling cron as --service option is used");
        $self->{_cron} = 0;
    }

    # Handle package skipping option
    my $skip = delete $options->{skip};
    if ($skip) {
        map { $self->{_skip}->{$_} } split(/,+/, $skip);
    }

    $self->init();

    return $self;
}

sub init {
    my ($self) = @_;
    $self->{_type} = "typical" unless defined($self->{_type});
}

sub installed {
    my ($self) = @_;
    my ($installed) = $self->{_packages} ? values %{$self->{_packages}} : ();
    return $installed;
}

sub info {
    my $self = shift;
    return if $self->{_silent};
    map { print $_, "\n" } @_;
}

sub verbose {
    my $self = shift;
    $self->info(@_) if @_ && $self->{_verbose};
    return $self->{_verbose} && !$self->{_silent} ? 1 : 0;
}

sub _getDistro {
    my $self = shift;

    my $handle;

    if (-e '/etc/os-release') {
        open $handle, '/etc/os-release';
        die "Can't open '/etc/os-release': $!\n" unless defined($handle);

        my ($name, $version, $description);
        while (my $line = <$handle>) {
            chomp($line);
            $name        = $1 if $line =~ /^NAME="?([^"]+)"?/;
            $version     = $1 if $line =~ /^VERSION="?([^"]+)"?/;
            $version     = $1 if !$version && $line =~ /^VERSION_ID="?([^"]+)"?/;
            $description = $1 if $line =~ /^PRETTY_NAME="?([^"]+)"?/;
        }
        close $handle;

        my ($class) = grep { $name =~ $classes{$_} } keys(%classes);

        return $name, $version, $description, $class
            if $class;
    }

    # Otherwise analyze first line of a given file, see @distributions
    my $distro;
    foreach my $d ( @distributions ) {
        next unless -f $d->[0];
        $distro = $d;
        last;
    }
    return unless $distro;

    my ($file, $name, $regexp, $template, $class) = @{$distro};

    $self->verbose("Found distro: $name");

    open $handle, $file;
    die "Can't open '$file': $!\n" unless defined($handle);

    my $line = <$handle>;
    chomp $line;

    # Arch Linux has an empty release file
    my ($release, $version);
    if ($line) {
        $release   = sprintf $template, $line;
        ($version) = $line =~ /$regexp/;
    } else {
        $release = $template;
    }

    return $name, $version, $release, $class;
}

sub extract {
    my ($self, $archive, $extract) = @_;

    $self->{_archive} = $archive;

    return unless defined($extract);

    if ($extract eq "keep") {
        $self->info("Will keep extracted packages");
        $self->{_cleanpkg} = 0;
        return;
    }

    $self->info("Extracting $extract packages...");
    my @pkgs = grep { /^rpm|deb|snap$/ } split(/,+/, $extract);
    my $pkgs = $extract eq "all" ? "\\w+" : join("|", @pkgs);
    if ($pkgs) {
        my $count = 0;
        foreach my $name ($self->{_archive}->files()) {
            next unless $name =~ m|^pkg/(?:$pkgs)/(.+)$|;
            $self->verbose("Extracting $name to $1");
            $self->{_archive}->extract($name)
                or die "Failed to extract $name: $!\n";
            $count++;
        }
        $self->info($count ? "$count extracted package".($count==1?"":"s") : "No package extracted");
    } else {
        $self->info("Nothing to extract");
    }

    exit(0);
}

sub getDeps {
    my ($self, $ext) = @_;

    return unless $self->{_archive} && $ext;

    my @pkgs = ();
    my $count = 0;
    foreach my $name ($self->{_archive}->files()) {
        next unless $name =~ m|^pkg/$ext/deps/(.+)$|;
        $self->verbose("Extracting $ext deps $1");
        $self->{_archive}->extract($1)
            or die "Failed to extract $1: $!\n";
        $count++;
        push @pkgs, $1;
    }
    $self->info("$count extracted $ext deps package".($count==1?"":"s")) if $count;
    return @pkgs;
}

sub configure {
    my ($self, $folder) = @_;

    $folder = "/etc/glpi-agent/conf.d" unless $folder;

    # Check if a configuration exists in archive
    my @configs = grep { m{^config/[^/]+\.(cfg|crt|pem)$} } $self->{_archive}->files();

    # We should also check existing installed config to support transparent upgrades but
    # only if no configuration option has been provided
    my $installed_config = "$folder/00-install.cfg";
    my $current_config;
    if (-e $installed_config && ! keys(%{$self->{_options}})) {
        push @configs, $installed_config;
        my $fh;
        open $fh, "<", $installed_config
            or die "Can't read $installed_config: $!\n";
        $current_config = <$fh>;
        close($fh);
    }

    # Ask configuration unless in silent mode, request or server or local is given as option
    if (!$self->{_silent} && !$self->{_dont_ask} && !($self->{_options}->{server} || $self->{_options}->{local})) {
        my (@cfg) = grep { m/\.cfg$/ } @configs;
        if (@cfg) {
            # Check if configuration provides server or local
            foreach my $cfg (@cfg) {
                my $content = $cfg eq $installed_config ? $current_config : $self->{_archive}->content($cfg);
                if ($content =~ /^(server|local)\s*=\s*\S/m) {
                    $self->{_dont_ask} = 1;
                    last;
                }
            }
        }
        # Only ask configuration if no server
        $self->ask_configure() unless $self->{_dont_ask};
    }

    # Check to use current user proxy environment
    if (!$self->{_options}->{proxy} && $self->{_user_proxy}) {
        my $proxy = $ENV{HTTPS_PROXY} // $ENV{HTTP_PROXY};
        $self->{_options}->{proxy} = $proxy if $proxy;
    }

    if (keys(%{$self->{_options}})) {
        $self->info("Applying configuration...");
        die "Can't apply configuration without $folder folder\n"
            unless -d $folder;

        my $fh;
        open $fh, ">", $installed_config
            or die "Can't create $installed_config: $!\n";
        $self->verbose("Writing configuration in $installed_config");
        foreach my $option (sort keys(%{$self->{_options}})) {
            my $value = $self->{_options}->{$option} // "";
            $self->verbose("Adding: $option = $value");
            print $fh "$option = $value\n";
        }
        close($fh);
    } else {
        $self->info("No configuration to apply") unless @configs;
    }

    foreach my $config (@configs) {
        next if $config eq $installed_config;
        my ($cfg) = $config =~ m{^confs/([^/]+\.(cfg|crt|pem))$};
        die "Can't install $cfg configuration without $folder folder\n"
            unless -d $folder;
        $self->info("Installing $cfg config in $folder");
        unlink "$folder/$cfg";
        $self->{_archive}->extract($config, "$folder/$cfg");
    }
}

sub ask_configure {
    my ($self) = @_;

    $self->info("glpi-agent is about to be installed as ".($self->{_service} ? "service" : "cron task"));

    if (defined($self->{_options}->{server})) {
        if (length($self->{_options}->{server})) {
            $self->info("GLPI server will be configured to: ".$self->{_options}->{server});
        } else {
            $self->info("Disabling server configuration");
        }
    } else {
        print "\nProvide an url to configure GLPI server:\n> ";
        my $server = <STDIN>;
        chomp($server);
        $self->{_options}->{server} = $server if length($server);
    }

    if (defined($self->{_options}->{local})) {
        if (! -d $self->{_options}->{local}) {
            $self->info("Not existing local inventory path, clearing: ".$self->{_options}->{local});
            delete $self->{_options}->{local};
        } elsif (length($self->{_options}->{local})) {
            $self->info("Local inventory path will be configured to: ".$self->{_options}->{local});
        } else {
            $self->info("Disabling local inventory");
        }
    }
    while (!defined($self->{_options}->{local})) {
        print "\nProvide a path to configure local inventory run or leave it empty:\n> ";
        my $local = <STDIN>;
        chomp($local);
        last unless length($local);
        if (-d $local) {
            $self->{_options}->{local} = $local;
        } else {
            $self->info("Not existing local inventory path: $local");
        }
    }

    if (defined($self->{_options}->{tag})) {
        if (length($self->{_options}->{tag})) {
            $self->info("Inventory tag will be configured to: ".$self->{_options}->{tag});
        } else {
            $self->info("Using empty inventory tag");
        }
    } else {
        print "\nProvide a tag to configure or leave it empty:\n> ";
        my $tag = <STDIN>;
        chomp($tag);
        $self->{_options}->{tag} = $tag if length($tag);
    }
}

sub install {
    my ($self) = @_;

    die "Install not supported on $self->{_release} linux distribution ($self->{_name}:$self->{_version})\n"
        unless $self->{_installed};

    $self->configure();

    if ($self->{_service}) {
        $self->install_service();

        # If requested, ask service to run inventory now sending it USR1 signal
        # If requested, still run inventory now
        if ($self->{_runnow}) {
            # Wait a little so the service won't misunderstand SIGUSR1 signal
            sleep 1;
            $self->info("Asking service to run inventory now as requested...");
            $self->system("systemctl -s SIGUSR1 kill glpi-agent");
        }
    } elsif ($self->{_cron}) {
        $self->install_cron();

        # If requested, still run inventory now
        if ($self->{_runnow}) {
            $self->info("Running inventory now as requested...");
            $self->system( $self->{_bin} );
        }
    }
    $self->clean_packages();
}

sub clean {
    my ($self) = @_;
    die "Can't clean glpi-agent related files if it is currently installed\n" if keys(%{$self->{_packages}});
    $self->info("Cleaning...");
    $self->run("rm -rf /etc/glpi-agent /var/lib/glpi-agent");
}

sub run {
    my ($self, $command) = @_;
    return unless $command;
    $self->verbose("Running: $command");
    system($command . ($self->verbose ? "" : " >/dev/null"));
    if ($? == -1) {
        die "Failed to run $command: $!\n";
    } elsif ($? & 127) {
        die "Failed to run $command: got signal ".($? & 127)."\n";
    }
    return $? >> 8;
}

sub uninstall {
    my ($self) = @_;
    die "Uninstall not supported on $self->{_release} linux distribution ($self->{_name}:$self->{_version})\n";
}

sub install_service {
    my ($self) = @_;
    $self->info("Enabling glpi-agent service...");

    # Always stop the service if necessary to be sure configuration is applied
    my $isactivecmd = "systemctl is-active glpi-agent" . ($self->verbose ? "" : " 2>/dev/null");
    $self->system("systemctl stop glpi-agent")
        if qx{$isactivecmd} eq "active";

    my $ret = $self->run("systemctl enable glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to enable glpi-agent service") if $ret;

    $self->verbose("Starting glpi-agent service...");
    $ret = $self->run("systemctl reload-or-restart glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    $self->info("Failed to start glpi-agent service") if $ret;
}

sub install_cron {
    my ($self) = @_;
    die "Installing as cron is not supported on $self->{_release} linux distribution ($self->{_name}:$self->{_version})\n";
}

sub uninstall_service {
    my ($self) = @_;
    $self->info("Disabling glpi-agent service...");

    my $isactivecmd = "systemctl is-active glpi-agent" . ($self->verbose ? "" : " 2>/dev/null");
    $self->system("systemctl stop glpi-agent")
        if qx{$isactivecmd} eq "active";

    my $ret = $self->run("systemctl disable glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to disable glpi-agent service") if $ret;
}

sub clean_packages {
    my ($self) = @_;
    if ($self->{_cleanpkg} && ref($self->{_installed}) eq 'ARRAY') {
        $self->verbose("Cleaning extracted packages");
        unlink @{$self->{_installed}};
        delete $self->{_installed};
    }
}

sub allowDowngrade {
    my ($self) = @_;
    $self->{_downgrade} = 1;
}

sub downgradeAllowed {
    my ($self) = @_;
    return $self->{_downgrade};
}

sub which {
    my ($self, $cmd) = @_;
    $cmd = qx{which $cmd 2>/dev/null};
    chomp $cmd;
    return $cmd;
}

sub system {
    my ($self, $cmd) = @_;
    $self->verbose("Running: $cmd");
    return system($cmd . ($self->verbose ? "" : " >/dev/null 2>&1"));
}

1;
