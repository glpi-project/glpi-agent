package FusionInventory::Agent::Task::Inventory::Generic::Processes;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Unix;

use constant    category    => "process";

sub isEnabled {
    return
        OSNAME ne 'MSWin32' &&
        canRun('ps');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $process (getProcesses(logger => $logger)) {
        $inventory->addEntry(
            section => 'PROCESSES',
            entry   => $process
        );
    }
}

1;
