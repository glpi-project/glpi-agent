package GLPI::Agent::Task::Inventory::Generic::Ipmi::Fru;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('ipmitool');
}

sub doInventory {}

1;
