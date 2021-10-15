package GLPI::Agent::Task::Inventory::Linux::OS;

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
