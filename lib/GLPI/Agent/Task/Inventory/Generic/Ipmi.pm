package FusionInventory::Agent::Task::Inventory::Generic::Ipmi;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

sub isEnabled {
    return unless canRun('ipmitool');
}

sub doInventory {}

1;
