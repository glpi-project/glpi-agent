package
    DebDistro;

use strict;
use warnings;

use parent 'LinuxDistro';

BEGIN {
    $INC{"DebDistro.pm"} = __FILE__;
}

use InstallerVersion;

my %DebPackages = (
    "glpi-agent"                => qr/^inventory$/i,
    "glpi-agent-task-network"   => qr/^netdiscovery|netinventory|network$/i,
    "glpi-agent-task-collect"   => qr/^collect$/i,
    "glpi-agent-task-esx"       => qr/^esx$/i,
    "glpi-agent-task-deploy"    => qr/^deploy$/i,
    #"glpi-agent-task-wakeonlan" => qr/^wakeonlan|wol$/i,
);

my %DebInstallTypes = (
    all     => [ qw(
        glpi-agent
        glpi-agent-task-network
        glpi-agent-task-collect
        glpi-agent-task-esx
        glpi-agent-task-deploy
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
    foreach my $deb (keys(%DebPackages)) {
        my $version = qx(dpkg-query --show --showformat='\${Version}' $deb 2>/dev/null);
        next if $?;
        $version =~ s/^\d+://;
        $self->{_packages}->{$deb} = $version;
    }

    # Try to figure out installation type from installed packages
    if ($self->{_packages} && !$self->{_type}) {
        my $installed = join(",", sort keys(%{$self->{_packages}}));
        foreach my $type (keys(%DebInstallTypes)) {
            my $install_type = join(",", sort @{$DebInstallTypes{$type}});
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

sub _extract_deb {
    my ($self, $deb) = @_;
    my $pkg = $deb."_".InstallerVersion::VERSION()."_all.deb";
    $self->verbose("Extracting $pkg ...");
    $self->{_archive}->extract("pkg/deb/$pkg")
        or die "Failed to extract $pkg: $!\n";
    return $pkg;
}

sub install {
    my ($self) = @_;

    $self->verbose("Trying to install glpi-agent v".InstallerVersion::VERSION()." on $self->{_release} release ($self->{_name}:$self->{_version})...");

    my $type = $self->{_type} // "typical";
    my %pkgs = qw( glpi-agent 1 );
    if ($DebInstallTypes{$type}) {
        map { $pkgs{$_} = 1 } @{$DebInstallTypes{$type}};
    } else {
        foreach my $task (split(/,/, $type)) {
            my ($pkg) = grep { $DebPackages{$_} && $task =~ $DebPackages{$_} } keys(%DebPackages);
            $pkgs{$pkg} = 1 if $pkg;
        }
    }

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

    my @pkgs = sort keys(%pkgs);
    if (@pkgs) {
        # The archive may have been prepared for a specific distro with expected deps
        # So we just need to install them too
        map { $pkgs{$_} = $_ } $self->getDeps("deb");

        foreach my $pkg (@pkgs) {
            $pkgs{$pkg} = $self->_extract_deb($pkg);
        }

        my @debs = sort values(%pkgs);
        my $command = "apt -y install @debs";
        my $err = $self->run($command);
        die "Failed to install glpi-agent\n" if $err;
        $self->{_installed} = \@debs;
    } else {
        $self->{_installed} = 1;
    }

    # Call parent installer to configure and install service or crontab
    $self->SUPER::install();
}

sub uninstall {
    my ($self) = @_;

    my @debs = sort keys(%{$self->{_packages}});

    return $self->info("glpi-agent is not installed")
        unless @debs;

    $self->info(
        @debs == 1 ? "Uninstalling glpi-agent package..." :
            "Uninstalling ".scalar(@debs)." glpi-agent related packages..."
    );
    my $err = $self->run("apt -y purge @debs");
    die "Failed to uninstall glpi-agent\n" if $err;

    map { delete $self->{_packages}->{$_} } @debs;

    # Also remove cron file if found
    unlink "/etc/cron.hourly/glpi-agent" if -e "/etc/cron.hourly/glpi-agent";
}

sub clean {
    my ($self) = @_;

    $self->SUPER::clean();

    unlink "/etc/default/glpi-agent" if -e "/etc/default/glpi-agent";
}

sub install_cron {
    my ($self) = @_;

    $self->info("glpi-agent will be run every hour via cron");
    $self->verbose("Disabling glpi-agent service...");
    my $ret = $self->run("/usr/bin/systemctl disable glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to disable glpi-agent service") if $ret;
    $self->verbose("Stopping glpi-agent service if running...");
    $ret = $self->run("/usr/bin/systemctl stop glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to stop glpi-agent service") if $ret;

    $self->verbose("Installin glpi-agent hourly cron file...");
    open my $cron, ">", "/etc/cron.hourly/glpi-agent"
        or die "Can't create hourly crontab for glpi-agent: $!\n";
    print $cron q{
#!/bin/bash
NAME=glpi-agent
LOG=/var/log/$NAME/$NAME.log

exec >>$LOG 2>&1

[ -f /etc/default/$NAME ] || exit 0
source /etc/default/$NAME
export PATH

: ${OPTIONS:=--wait 120 --lazy}

echo "[$(date '+%c')] Running $NAME $OPTIONS"
/usr/bin/$NAME $OPTIONS
echo "[$(date '+%c')] End of cron job ($PATH)"
};
    close($cron);
    if (! -e "/etc/default/glpi-agent") {
        $self->verbose("Installin glpi-agent system default config...");
        open my $default, ">", "/etc/default/glpi-agent"
            or die "Can't create system default config for glpi-agent: $!\n";
        print $default q{
# By default, ask agent to wait a random time
OPTIONS="--wait 120"

# By default, runs are lazy, so the agent won't contact the server before it's time to
OPTIONS="$OPTIONS --lazy"
};
        close($default);
    }
}

1;
