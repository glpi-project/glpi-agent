package GLPI::Agent::Task::Inventory::Generic::PCI;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('lspci');
}

sub doInventory {}

1;
