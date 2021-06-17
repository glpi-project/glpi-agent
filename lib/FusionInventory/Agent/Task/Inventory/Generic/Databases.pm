package FusionInventory::Agent::Task::Inventory::Generic::Databases;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use constant    category    => "database";

sub isEnabled {
    return 1;
}

sub doInventory {}

1;
