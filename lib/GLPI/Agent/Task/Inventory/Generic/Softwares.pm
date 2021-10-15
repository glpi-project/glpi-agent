package GLPI::Agent::Task::Inventory::Generic::Softwares;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use constant    category    => "software";

sub isEnabled {
    return 1;
}

sub doInventory {}

1;
