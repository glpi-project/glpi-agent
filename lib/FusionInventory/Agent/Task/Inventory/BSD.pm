package FusionInventory::Agent::Task::Inventory::BSD;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME =~ /freebsd|openbsd|netbsd|gnukfreebsd|gnuknetbsd|dragonfly/;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # basic operating system informations
    my $kernelVersion = getFirstLine(command => 'uname -v');
    my $kernelRelease = getFirstLine(command => 'uname -r');

    my $boottime = getFirstMatch(
        command => "sysctl -n kern.boottime",
        pattern => qr/sec = (\d+)/
    );

    my $name = canRun('lsb_release') ?
        getFirstMatch(
            command => 'lsb_release -d',
            pattern => qr/Description:\s+(.+)/
        ) : OSNAME;

    $inventory->setHardware({
        OSNAME     => $name,
        OSVERSION  => $kernelRelease,
        OSCOMMENTS => $kernelVersion,
    });

    $inventory->setOperatingSystem({
        NAME           => $name,
        FULL_NAME      => OSNAME,
        VERSION        => $kernelRelease,
        KERNEL_VERSION => $kernelRelease,
        BOOT_TIME      => getFormatedLocalTime($boottime)
    });
}

1;
