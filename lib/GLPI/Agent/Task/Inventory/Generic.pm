package GLPI::Agent::Task::Inventory::Generic;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

sub isEnabled {
    return 1;
}

sub doInventory {}

1;
