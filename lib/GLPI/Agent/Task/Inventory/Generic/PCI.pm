package FusionInventory::Agent::Task::Inventory::Generic::PCI;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

sub isEnabled {
    return canRun('lspci');
}

sub doInventory {}

1;
