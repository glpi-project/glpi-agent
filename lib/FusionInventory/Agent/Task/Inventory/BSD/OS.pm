package FusionInventory::Agent::Task::Inventory::BSD::OS;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # basic operating system informations
    my $kernelRelease = getFirstLine(
        logger  => $logger,
        command => 'uname -r'
    );

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
        ) : $OSNAME;

    $inventory->setOperatingSystem({
        NAME           => $name,
        FULL_NAME      => $OSNAME,
        VERSION        => $kernelRelease,
        KERNEL_VERSION => $kernelRelease,
        BOOT_TIME      => getFormatedLocalTime($boottime)
    });
}

1;
