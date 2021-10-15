package GLPI::Agent::Task::Inventory::Virtualization;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use constant    category    => "virtualmachine";

sub isEnabled {
    return 1;
}

sub doInventory {
}

1;
