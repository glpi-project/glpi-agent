package
    DebDistro;

use strict;
use warnings;

use parent 'LinuxDistro';

BEGIN {
    $INC{"DebDistro.pm"} = __FILE__;
}

use Fcntl qw(:flock);
use InstallerVersion;

# Maximum time in seconds to wait for APT/DPKG locks to be released
my $APT_LOCK_WAIT_MAX = 300;
# Interval in seconds between lock-availability checks
my $APT_LOCK_RETRY_INTERVAL = 10;

my $DEBREVISION = "1";
my $DEBVERSION = InstallerVersion::VERSION();
# Add package a revision on official releases
$DEBVERSION .= "-$DEBREVISION" unless $DEBVERSION =~ /-.+$/;

my %DebPackages = (
    "glpi-agent"                => qr/^inventory$/i,
    "glpi-agent-task-network"   => qr/^netdiscovery|netinventory|network$/i,
    "glpi-agent-task-collect"   => qr/^collect$/i,
    "glpi-agent-task-esx"       => qr/^esx$/i,
    "glpi-agent-task-deploy"    => qr/^deploy$/i,
    #"glpi-agent-task-wakeonlan" => qr/^wakeonlan|wol$/i,
    "libiec61850-glpi-agent"    => qr/^iec61850$/i,
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
    "all+iec61850"  => [ qw(
        glpi-agent
        glpi-agent-task-network
        glpi-agent-task-collect
        glpi-agent-task-esx
        glpi-agent-task-deploy
        libiec61850-glpi-agent
    ) ],
    iec61850 => [ qw(
        glpi-agent
        glpi-agent-task-network
        libiec61850-glpi-agent
    ) ],
);

sub init {
    my ($self) = @_;

    # Store installation status for each supported package
    foreach my $deb (keys(%DebPackages)) {
        my $query = qx(dpkg-query -s $deb 2>/dev/null);
        next if $?;
        next unless $query =~ /^Status:\s+install ok installed$/mi;
        my ($version) = $query =~ /^Version:\s+(.*)$/mi;
        $version =~ s/^\d+://;
        $self->{_packages}->{$deb} = $version;
    }

    # Try to figure out installation type from installed packages
    if ($self->{_packages} && !$self->{_type}) {
        my $installed = join(",", sort keys(%{$self->{_packages}}));
        $self->{_type} = "custom";
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
    my $pkg = $deb."_${DEBVERSION}_all.deb";
    if ($deb eq "libiec61850-glpi-agent") {
        # Actually only x86_64 arch is supported for libiec61850-glpi-agent
        $pkg = $deb."_${DEBVERSION}_amd64.deb";
    }
    $self->verbose("Extracting $pkg ...");
    $self->{_archive}->extract("pkg/deb/$pkg")
        or die "Failed to extract $pkg: $!\n";
    my $pwd = $ENV{PWD} || qx/pwd/;
    chomp($pwd);
    return $pwd =~ /\s/ ? "'$pwd/$pkg'" : "$pwd/$pkg";
}

sub _check_dpkg_state {
    my ($self) = @_;

    # dpkg --audit exits non-zero when packages are in a broken state
    # (half-installed, half-configured, triggers-awaited, triggers-pending,
    # or packages with missing/unmet dependencies) and prints a description
    # of each problem.  Exit status 0 means the database is consistent.
    my $audit = qx{dpkg --audit 2>&1};
    if ($? != 0) {
        $self->info("WARNING: dpkg has reported package inconsistencies:");
        $self->info("  $_") for grep { /\S/ } split(/\n/, $audit);
        $self->info("Fix the broken packages before retrying:");
        $self->info("  sudo dpkg --configure -a");
        $self->info("  sudo apt --fix-broken install");
        die "Inconsistent dpkg state detected, aborting installation\n";
    }
}

sub _lock_holder_info {
    my ($lockfile) = @_;

    # Resolve the inode of the lock file so we can match it in /proc/locks.
    my @st = stat($lockfile);
    return "" unless @st;
    my $inode = $st[1];

    # /proc/locks format (one entry per line):
    #   id: TYPE ADVISORY WRITE pid maj:min:inode start end
    # The inode field is decimal; device numbers are hex.
    open(my $fh, '<', '/proc/locks') or return "";
    while (my $line = <$fh>) {
        next unless $line =~ /\bWRITE\b\s+(\d+)\s+[0-9a-f]+:[0-9a-f]+:(\d+)\b/i;
        my ($pid, $lock_inode) = ($1, $2);
        next unless $lock_inode == $inode;
        close($fh);
        # Retrieve the process name from the kernel comm file (always available).
        my $name = "";
        if (open(my $ch, '<', "/proc/$pid/comm")) {
            chomp($name = <$ch> // "");
            close($ch);
        }
        return $name ? "$name (PID $pid)" : "PID $pid";
    }
    close($fh);
    return "";
}

sub _wait_for_apt_lock {
    my ($self) = @_;

    # Honour the timeout configured in APT itself; fall back to the built-in default.
    # apt-config dump outputs lines like: Binary::apt::DPkg::Lock::Timeout "120";
    # A value of 0 (APT default) or -1 means "no timeout / wait forever", which
    # would cause the installer to hang indefinitely, so fall back in those cases.
    my $max_wait = $APT_LOCK_WAIT_MAX;
    my $timeout_cfg = qx{apt-config dump 'Binary::apt::DPkg::Lock::Timeout' 2>/dev/null};
    if ($timeout_cfg && $timeout_cfg =~ /Binary::apt::DPkg::Lock::Timeout\s+"(-?\d+)"/) {
        my $apt_timeout = int($1);
        if ($apt_timeout > 0) {
            $max_wait = $apt_timeout;
            $self->verbose("Using APT lock timeout from apt config: ${max_wait}s");
        } else {
            $self->verbose("APT lock timeout is ${apt_timeout} (no limit); using built-in default: ${max_wait}s");
        }
    }

    # All lock files that serialise APT/DPKG operations
    my @lock_files = (
        "/var/lib/dpkg/lock-frontend",
        "/var/lib/dpkg/lock",
        "/var/cache/apt/archives/lock",
    );

    my $waited   = 0;
    my $reported = 0;
    while (1) {
        my @locked;
        foreach my $lockfile (@lock_files) {
            next unless -e $lockfile;
            if (open(my $fh, '<', $lockfile)) {
                # Try a non-blocking exclusive lock; if it fails the file is
                # already held by another process.
                if (!flock($fh, LOCK_EX | LOCK_NB)) {
                    push @locked, $lockfile;
                } else {
                    flock($fh, LOCK_UN);
                }
                close($fh);
            }
        }

        last unless @locked; # All clear — proceed with installation

        if (!$reported) {
            # Identify which process is holding the first lock we found.
            my $holder = _lock_holder_info($locked[0]);
            $self->info("APT/DPKG is currently locked"
                . ($holder ? " by $holder" : " by another process") . ".");
            $self->info("Waiting up to ${max_wait}s for the lock to be released...");
            $reported = 1;
        }

        if ($waited >= $max_wait) {
            my @details = map {
                my $h = _lock_holder_info($_);
                $h ? "$_ (held by $h)" : $_;
            } @locked;
            die "APT/DPKG lock still held after ${max_wait}s: "
              . join(", ", @details) . "\n"
              . "Stop that process, then retry the installation.\n";
        }

        sleep($APT_LOCK_RETRY_INTERVAL);
        $waited += $APT_LOCK_RETRY_INTERVAL;
        $self->info(
            "Still waiting for APT/DPKG lock to be released... "
            . "(${waited}s / ${max_wait}s)"
        );
    }

    $self->info("APT/DPKG lock is now available, proceeding with installation.")
        if $reported;
}

sub install {
    my ($self) = @_;

    $self->verbose("Trying to install glpi-agent v$DEBVERSION on $self->{_release} release ($self->{_name}:$self->{_version})...");

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
                if ($self->{_packages}->{$pkg} eq $DEBVERSION) {
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
        map { $pkgs{$_} = $_ } $self->getDeps("deb");

        foreach my $pkg (@pkgs) {
            $pkgs{$pkg} = $self->_extract_deb($pkg);
        }

        if (!$self->{_skip}->{dmidecode} && qx{uname -m 2>/dev/null} =~ /^(i.86|x86_64)$/ && ! $self->which("dmidecode")) {
            $self->verbose("Trying to also install dmidecode ...");
            $pkgs{dmidecode} = "dmidecode";
        }

        # Be sure to have pci.ids & usb.ids on recent distro as its dependencies were removed
        # from packaging to support older distros
        if (!-e "/usr/share/misc/pci.ids" && qx{dpkg-query --show --showformat='\${Package}' pciutils 2>/dev/null}) {
            $self->verbose("Trying to also install pci.ids ...");
            $pkgs{"pci.ids"} = "pci.ids";
        }
        if (!-e "/usr/share/misc/usb.ids" && qx{dpkg-query --show --showformat='\${Package}' usbutils 2>/dev/null}) {
            $self->verbose("Trying to also install usb.ids ...");
            $pkgs{"usb.ids"} = "usb.ids";
        }

        my @debs = sort values(%pkgs);
        my @options = ( "-y" );
        push @options, "--allow-downgrades" if $self->downgradeAllowed();

        # Pre-flight: detect broken dpkg state and wait for any APT/DPKG locks
        # before invoking apt so the user always gets actionable diagnostics.
        $self->_check_dpkg_state();
        $self->_wait_for_apt_lock();

        my $command = "apt install @options @debs 2>/dev/null";
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

    $self->uninstall_service();

    $self->info(
        @debs == 1 ? "Uninstalling glpi-agent package..." :
            "Uninstalling ".scalar(@debs)." glpi-agent related packages..."
    );
    my $err = $self->run("apt purge -y --autoremove @debs 2>/dev/null");
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
    my $ret = $self->run("systemctl disable glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to disable glpi-agent service") if $ret;
    $self->verbose("Stopping glpi-agent service if running...");
    $ret = $self->run("systemctl stop glpi-agent" . ($self->verbose ? "" : " 2>/dev/null"));
    return $self->info("Failed to stop glpi-agent service") if $ret;

    $self->verbose("Installing glpi-agent hourly cron file...");
    my $cron = $self->open_os_file('/etc/cron.hourly/glpi-agent', '>')
        or die "Can't create hourly crontab for glpi-agent: $!\n";
    print $cron q{#!/bin/bash

NAME=glpi-agent
LOG=/var/log/$NAME-cron.log

exec >>$LOG 2>&1

[ -f /etc/default/$NAME ] || exit 0
source /etc/default/$NAME
export PATH

: ${OPTIONS:=--wait 120 --lazy}

echo "[$(date '+%c')] Running $NAME $OPTIONS"
/usr/bin/$NAME $OPTIONS
echo "[$(date '+%c')] End of cron job ($PATH)"
};
    $self->close_os_file();
    $self->chmod_os_file(0755, '/etc/cron.hourly/glpi-agent');
    unless ($self->os_file_exists('/etc/default/glpi-agent')) {
        $self->verbose("Installing glpi-agent system default config...");
        my $default = $self->open_os_file('/etc/default/glpi-agent', '>')
            or die "Can't create system default config for glpi-agent: $!\n";
        print $default q{
# By default, ask agent to wait a random time
OPTIONS="--wait 120"

# By default, runs are lazy, so the agent won't contact the server before it's time to
OPTIONS="$OPTIONS --lazy"
};
        $self->close_os_file();
    }
}

1;
