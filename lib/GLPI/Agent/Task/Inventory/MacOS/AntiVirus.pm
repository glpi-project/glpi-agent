package GLPI::Agent::Task::Inventory::MacOS::AntiVirus;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use constant    category    => "antivirus";

sub isEnabled {
    return 1;
}

sub doInventory {
}

1;
