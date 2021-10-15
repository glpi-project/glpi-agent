package GLPI::Agent::Task::Inventory::BSD::OS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # basic operating system informations
    my $kernelRelease = Uname("-r");
    my $kernelVersion = Uname("-v");

    my $boottime = getFirstMatch(
        logger  => $logger,
        command => "sysctl -n kern.boottime",
        pattern => qr/sec = (\d+)/
    );

    my $name = canRun('lsb_release') ?
        getFirstMatch(
            logger  => $logger,
            command => 'lsb_release -d',
            pattern => qr/Description:\s+(.+)/
        ) : OSNAME;

    $inventory->setOperatingSystem({
        NAME           => $name,
        FULL_NAME      => OSNAME,
        VERSION        => $kernelRelease,
        KERNEL_VERSION => $kernelVersion,
        BOOT_TIME      => getFormatedLocalTime($boottime)
    });
}

1;
