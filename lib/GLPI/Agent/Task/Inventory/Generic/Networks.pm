package FusionInventory::Agent::Task::Inventory::Generic::Networks;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use constant    category    => "network";

sub isEnabled {
    return 1;
}

sub doInventory {}

1;
