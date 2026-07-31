package GLPI::Agent::Task::Inventory::Linux::License;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use constant    category    => "licenseinfo";

sub isEnabled {
    return 1;
}

sub doInventory {
}

1;
