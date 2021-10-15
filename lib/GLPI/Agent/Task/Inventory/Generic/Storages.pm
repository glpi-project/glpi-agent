package GLPI::Agent::Task::Inventory::Generic::Storages;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use constant    category    => "storage";

sub isEnabled {
    return 1;
}

sub doInventory {}

1;
