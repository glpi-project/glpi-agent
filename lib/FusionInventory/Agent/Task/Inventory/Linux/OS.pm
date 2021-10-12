package FusionInventory::Agent::Task::Inventory::Linux::OS;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $kernelRelease = Uname("-r");

    my $hostid = getFirstLine(
        logger  => $logger,
        command => 'hostid'
    );

    $inventory->setOperatingSystem({
        HOSTID         => $hostid,
        KERNEL_VERSION => $kernelRelease,
    });
}

1;
