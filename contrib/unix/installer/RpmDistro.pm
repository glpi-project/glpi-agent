package
    RpmDistro;

use strict;
use warnings;

use parent 'LinuxDistro';

BEGIN {
    $INC{"RpmDistro.pm"} = __FILE__;
}

use InstallerVersion;

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
    my $pkg = "$rpm-".InstallerVersion::VERSION().".noarch.rpm";
    $self->verbose("Extracting $pkg ...");
    $self->{_archive}->extract("pkg/rpm/$pkg")
        or die "Failed to extract $pkg: $!\n";
    return $pkg;
}

sub install {
    my ($self) = @_;

    $self->verbose("Trying to install glpi-agent v".InstallerVersion::VERSION()." on $self->{_release} release ($self->{_name}:$self->{_version})...");

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
                if ($self->{_packages}->{$pkg} eq InstallerVersion::VERSION()) {
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

        if (!$self->{_skip}->{dmidecode} && qx{uname -m 2>/dev/null} =~ /^(i.86|x86_64)$/ && ! qx{which dmidecode 2>/dev/null}) {
            $self->verbose("Trying to also install dmidecode ...");
            $pkgs{dmidecode} = "dmidecode";
        }

        my @rpms = sort values(%pkgs);
        $self->_prepareDistro();
        my $command = $self->{_yum} ? "yum -y install @rpms" :
            $self->{_dnf} ? "dnf -y install @rpms" : "";
        die "Unsupported rpm based platform\n" unless $command;
        my $err = $self->run($command);
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

    my ($v) = $self->{_version} =~ /^(\d+)/;

    # Enable repo for RedHat or CentOS
    if ($self->{_name} =~ /redhat/i) {
        # On RHEL 8, enable codeready-builder repo
        if ($v eq "8") {
            my $arch = qx(arch);
            $self->verbose("Checking codeready-builder-for-rhel-8-$arch-rpms repository repository is enabled");
            my $ret = $self->run("subscription-manager repos --enable codeready-builder-for-rhel-8-$arch-rpms");
            die "Can't enable codeready-builder-for-rhel-8-$arch-rpms repository: $!\n" if $ret;
        } elsif (int($v) < 8) {
            $self->{_yum} = 1;
            delete $self->{_dnf};
        }
    } elsif ($self->{_name} =~ /centos/i) {
        # On CentOS 8, we need PowerTools
        if ($v eq "8") {
            $self->verbose("Checking PowerTools repository is enabled");
            my $ret = $self->run("dnf config-manager --set-enabled powertools");
            die "Can't enable PowerTools repository: $!\n" if $ret;
        } elsif (int($v) < 8) {
            $self->{_yum} = 1;
            delete $self->{_dnf};
        }
    }

    # We always need RHEL
    my $epel = qx(rpm -q --queryformat '%{VERSION}' epel-release);
    if ($? == 0 && $epel eq $v) {
        $self->verbose("EPEL $v repository still installed");
    } else {
        $self->info("Installing EPEL $v repository...");
        my $epelcmd = "yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$v.noarch.rpm";
        my $ret = $self->run($epelcmd);
        die "Can't install EPEL $v repository: $!\n" if $ret;
    }
}

sub uninstall {
    my ($self) = @_;

    my @rpms = sort keys(%{$self->{_packages}});

    unless (@rpms) {
        $self->info("glpi-agent is not installed");
        return;
    }

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

sub install_cron {
    my ($self) = @_;
    # glpi-agent-cron package should have been installed
    $self->info("glpi-agent will be run every hour via cron");
    $self->verbose("Disabling glpi-agent service...");
    my $ret = $self->run("/usr/bin/systemctl disable glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to disable glpi-agent service") if $ret;
    $self->verbose("Stopping glpi-agent service if running...");
    $ret = $self->run("/usr/bin/systemctl stop glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to stop glpi-agent service") if $ret;
    # Finally update /etc/sysconfig/glpi-agent to enable cron mode
    $self->verbose("Enabling glpi-agent cron mode...");
    $ret = $self->run("sed -i -e s/=none/=cron/ /etc/sysconfig/glpi-agent");
    $self->info("Failed to update /etc/sysconfig/glpi-agent") if $ret;
}

1;
