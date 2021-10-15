package GLPI::Agent::Task::Inventory::Generic::Ipmi;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
    return unless canRun('ipmitool');
}

sub doInventory {}

1;
