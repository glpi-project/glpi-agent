package
    RpmDistro;

use strict;
use warnings;

use parent 'LinuxDistro';

BEGIN {
    $INC{"RpmDistro.pm"} = __FILE__;
}

use InstallerVersion;

my $RPMREVISION = "1";
my $RPMVERSION = InstallerVersion::VERSION();
# Add package a revision on official releases
$RPMVERSION .= "-$RPMREVISION" unless $RPMVERSION =~ /-.+$/;

my %RpmPackages = (
    "glpi-agent"                => qr/^inventory$/i,
    "glpi-agent-task-network"   => qr/^netdiscovery|netinventory|network$/i,
    "glpi-agent-task-collect"   => qr/^collect$/i,
    "glpi-agent-task-esx"       => qr/^esx$/i,
    "glpi-agent-task-deploy"    => qr/^deploy$/i,
    "glpi-agent-task-wakeonlan" => qr/^wakeonlan|wol$/i,
    "glpi-agent-cron"           => 0,
);

my %RpmInstallTypes = (
    all     => [ qw(
        glpi-agent
        glpi-agent-task-network
        glpi-agent-task-collect
        glpi-agent-task-esx
        glpi-agent-task-deploy
        glpi-agent-task-wakeonlan
    ) ],
    typical => [ qw(glpi-agent) ],
    network => [ qw(
        glpi-agent
        glpi-agent-task-network
    ) ],
);

sub init {
    my ($self) = @_;

    # Store installation status for each supported package
    foreach my $rpm (keys(%RpmPackages)) {
        my $version = qx(rpm -q --queryformat '%{VERSION}-%{RELEASE}' $rpm);
        next if $?;
        $self->{_packages}->{$rpm} = $version;
    }

    # Try to figure out installation type from installed packages
    if ($self->{_packages} && !$self->{_type}) {
        my $installed = join(",", sort keys(%{$self->{_packages}}));
        foreach my $type (keys(%RpmInstallTypes)) {
            my $install_type = join(",", sort @{$RpmInstallTypes{$type}});
            if ($installed eq $install_type) {
                $self->{_type} = $type;
                last;
            }
        }
        $self->verbose("Guessed installation type: $self->{_type}");
    }

    # Call parent init to figure out some defaults
    $self->SUPER::init();
}

sub _extract_rpm {
    my ($self, $rpm) = @_;
    my $pkg = "$rpm-$RPMVERSION.noarch.rpm";
    $self->verbose("Extracting $pkg ...");
    $self->{_archive}->extract("pkg/rpm/$pkg")
        or die "Failed to extract $pkg: $!\n";
    return $pkg;
}

sub install {
    my ($self) = @_;

    $self->verbose("Trying to install glpi-agent v$RPMVERSION on $self->{_release} release ($self->{_name}:$self->{_version})...");

    my $type = $self->{_type} // "typical";
    my %pkgs = qw( glpi-agent 1 );
    if ($RpmInstallTypes{$type}) {
        map { $pkgs{$_} = 1 } @{$RpmInstallTypes{$type}};
    } else {
        foreach my $task (split(/,/, $type)) {
            my ($pkg) = grep { $RpmPackages{$_} && $task =~ $RpmPackages{$_} } keys(%RpmPackages);
            $pkgs{$pkg} = 1 if $pkg;
        }
    }
    $pkgs{"glpi-agent-cron"} = 1 if $self->{_cron};

    # Check installed packages
    if ($self->{_packages}) {
        # Auto-select still installed packages
        map { $pkgs{$_} = 1 } keys(%{$self->{_packages}});

        foreach my $pkg (keys(%pkgs)) {
            if ($self->{_packages}->{$pkg}) {
                if ($self->{_packages}->{$pkg} eq $RPMVERSION) {
                    $self->verbose("$pkg still installed and up-to-date");
                    delete $pkgs{$pkg};
                } else {
                    $self->verbose("$pkg will be upgraded");
                }
            }
        }
    }

    # Don't install skipped packages
    map { delete $pkgs{$_} } keys(%{$self->{_skip}});

    my @pkgs = sort keys(%pkgs);
    if (@pkgs) {
        # The archive may have been prepared for a specific distro with expected deps
        # So we just need to install them too
        map { $pkgs{$_} = $_ } $self->getDeps("rpm");

        foreach my $pkg (@pkgs) {
            $pkgs{$pkg} = $self->_extract_rpm($pkg);
        }

        if (!$self->{_skip}->{dmidecode} && qx{uname -m 2>/dev/null} =~ /^(i.86|x86_64)$/ && ! $self->which("dmidecode")) {
            $self->verbose("Trying to also install dmidecode ...");
            $pkgs{dmidecode} = "dmidecode";
        }

        my @rpms = sort values(%pkgs);
        $self->_prepareDistro();
        my $command = $self->{_yum} ? "yum -y install @rpms" :
            $self->{_zypper} ? "zypper -n install -y --allow-unsigned-rpm @rpms" :
            $self->{_dnf} ? "dnf -y install @rpms" : "";
        die "Unsupported rpm based platform\n" unless $command;
        my $err = $self->system($command);
        if ($? >> 8 && $self->{_yum} && $self->downgradeAllowed()) {
            $err = $self->run("yum -y downgrade @rpms");
        }
        die "Failed to install glpi-agent\n" if $err;
        $self->{_installed} = \@rpms;
    } else {
        $self->{_installed} = 1;
    }

    # Call parent installer to configure and install service or crontab
    $self->SUPER::install();
}

sub _prepareDistro {
    my ($self) = @_;

    $self->{_dnf} = 1;

    # Still ready for Fedora
    return if $self->{_name} =~ /fedora/i;

    my $v = int($self->{_version} =~ /^(\d+)/ ? $1 : 0)
        or return;

    # Enable repo for RedHat or CentOS
    if ($self->{_name} =~ /red\s?hat/i) {
        # Since RHEL 8, enable codeready-builder repo
        if ($v < 8) {
            $self->{_yum} = 1;
            delete $self->{_dnf};
        } else {
            my $arch = qx(arch);
            chomp($arch);
            $self->verbose("Checking codeready-builder-for-rhel-$v-$arch-rpms repository repository is enabled");
            my $ret = $self->run("subscription-manager repos --enable codeready-builder-for-rhel-$v-$arch-rpms");
            die "Can't enable codeready-builder-for-rhel-$v-$arch-rpms repository: $!\n" if $ret;
        }
    } elsif ($self->{_name} =~ /oracle linux/i) {
        # On Oracle Linux server 8, we need "ol8_codeready_builder"
        if ($v >= 8) {
            $self->verbose("Checking Oracle Linux CodeReady Builder repository is enabled");
            my $ret = $self->run("dnf config-manager --set-enabled ol${v}_codeready_builder");
            die "Can't enable CodeReady Builder repository: $!\n" if $ret;
        }
    } elsif ($self->{_name} =~ /rocky|almalinux/i) {
        # On Rocky 8, we need PowerTools
        # On Rocky/AlmaLinux 9, we need CRB
        if ($v >= 9) {
            $self->verbose("Checking CRB repository is enabled");
            my $ret = $self->run("dnf config-manager --set-enabled crb");
            die "Can't enable CRB repository: $!\n" if $ret;
        } else {
            $self->verbose("Checking PowerTools repository is enabled");
            my $ret = $self->run("dnf config-manager --set-enabled powertools");
            die "Can't enable PowerTools repository: $!\n" if $ret;
        }
    } elsif ($self->{_name} =~ /centos/i) {
        # On CentOS 8, we need PowerTools
        # Since CentOS 9, we need CRB
        if ($v >= 9) {
            $self->verbose("Checking CRB repository is enabled");
            my $ret = $self->run("dnf config-manager --set-enabled crb");
            die "Can't enable CRB repository: $!\n" if $ret;
        } elsif ($v == 8) {
            $self->verbose("Checking PowerTools repository is enabled");
            my $ret = $self->run("dnf config-manager --set-enabled powertools");
            die "Can't enable PowerTools repository: $!\n" if $ret;
        } else {
            $self->{_yum} = 1;
            delete $self->{_dnf};
        }
    } elsif ($self->{_name} =~ /opensuse/i) {
        $self->{_zypper} = 1;
        delete $self->{_dnf};
        $self->verbose("Checking devel_languages_perl repository is enabled");
        # Always quiet this test even on verbose mode
        if ($self->run("zypper -n repos devel_languages_perl" . ($self->verbose ? " >/dev/null" : ""))) {
            $self->verbose("Installing devel_languages_perl repository...");
            my $release = $self->{_release};
            $release =~ s/ /_/g;
            my $ret = 0;
            foreach my $version ($self->{_version}, $release) {
                $ret = $self->run("zypper -n --gpg-auto-import-keys addrepo https://download.opensuse.org/repositories/devel:/languages:/perl/$version/devel:languages:perl.repo")
                    or last;
            }
            die "Can't install devel_languages_perl repository\n" if $ret;
        }
        $self->verbose("Enable devel_languages_perl repository...");
        $self->run("zypper -n modifyrepo -e devel_languages_perl")
            and die "Can't enable required devel_languages_perl repository\n";
        $self->verbose("Refresh devel_languages_perl repository...");
        $self->run("zypper -n --gpg-auto-import-keys refresh devel_languages_perl")
            and die "Can't refresh devel_languages_perl repository\n";
    }

    # We need EPEL only on redhat/centos
    unless ($self->{_zypper}) {
        my $epel = qx(rpm -q --queryformat '%{VERSION}' epel-release);
        if ($? == 0 && $epel eq $v) {
            $self->verbose("EPEL $v repository still installed");
        } else {
            $self->info("Installing EPEL $v repository...");
            my $cmd = $self->{_yum} ? "yum" : "dnf";
            if ( $self->system("$cmd -y install epel-release") != 0 ) {
                my $epelcmd = "$cmd -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$v.noarch.rpm";
                my $ret = $self->run($epelcmd);
                die "Can't install EPEL $v repository: $!\n" if $ret;
            }
        }
    }
}

sub uninstall {
    my ($self) = @_;

    my @rpms = sort keys(%{$self->{_packages}});

    unless (@rpms) {
        $self->info("glpi-agent is not installed");
        return;
    }

    $self->uninstall_service();

    $self->info(
        @rpms == 1 ? "Uninstalling glpi-agent package..." :
            "Uninstalling ".scalar(@rpms)." glpi-agent related packages..."
    );
    my $err = $self->run("rpm -e @rpms");
    die "Failed to uninstall glpi-agent\n" if $err;

    map { delete $self->{_packages}->{$_} } @rpms;
}

sub clean {
    my ($self) = @_;

    $self->SUPER::clean();

    unlink "/etc/sysconfig/glpi-agent" if -e "/etc/sysconfig/glpi-agent";
}

sub install_service {
    my ($self) = @_;

    return $self->SUPER::install_service() if $self->which("systemctl");

    unless ($self->which("chkconfig") && $self->which("service") && -d "/etc/rc.d/init.d") {
        return $self->info("Failed to enable glpi-agent service: unsupported distro");
    }

    $self->info("Enabling glpi-agent service using init file...");

    $self->verbose("Extracting init file ...");
    $self->{_archive}->extract("pkg/rpm/glpi-agent.init.redhat")
        or die "Failed to extract glpi-agent.init.redhat: $!\n";
    $self->verbose("Installing init file ...");
    $self->system("mv -vf glpi-agent.init.redhat /etc/rc.d/init.d/glpi-agent");
    $self->system("chmod +x /etc/rc.d/init.d/glpi-agent");
    $self->system("chkconfig --add glpi-agent") unless qx{chkconfig --list glpi-agent 2>/dev/null};
    $self->verbose("Trying to start service ...");
    $self->run("service glpi-agent restart");
}

sub install_cron {
    my ($self) = @_;
    # glpi-agent-cron package should have been installed
    $self->info("glpi-agent will be run every hour via cron");
    $self->verbose("Disabling glpi-agent service...");
    my $ret = $self->run("systemctl disable glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to disable glpi-agent service") if $ret;
    $self->verbose("Stopping glpi-agent service if running...");
    $ret = $self->run("systemctl stop glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to stop glpi-agent service") if $ret;
    # Finally update /etc/sysconfig/glpi-agent to enable cron mode
    $self->verbose("Enabling glpi-agent cron mode...");
    $ret = $self->run("sed -i -e s/=none/=cron/ /etc/sysconfig/glpi-agent");
    $self->info("Failed to update /etc/sysconfig/glpi-agent") if $ret;
}

sub uninstall_service {
    my ($self) = @_;

    return $self->SUPER::uninstall_service() if $self->which("systemctl");

    unless ($self->which("chkconfig") && $self->which("service") && -d "/etc/rc.d/init.d") {
        return $self->info("Failed to uninstall glpi-agent service: unsupported distro");
    }

    $self->info("Uninstalling glpi-agent service init script...");

    $self->verbose("Trying to stop service ...");
    $self->run("service glpi-agent stop");

    $self->verbose("Uninstalling init file ...");
    $self->system("chkconfig --del glpi-agent") if qx{chkconfig --list glpi-agent 2>/dev/null};
    $self->system("rm -vf /etc/rc.d/init.d/glpi-agent");
}

1;
