package FusionInventory::Agent::Task::Inventory::Generic::Storages;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use constant    category    => "storage";

sub isEnabled {
    return 1;
}

sub doInventory {}

1;
