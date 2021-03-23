package FusionInventory::Agent::Task::Inventory::Generic;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

sub isEnabled {
    return 1;
}

sub doInventory {}

1;
