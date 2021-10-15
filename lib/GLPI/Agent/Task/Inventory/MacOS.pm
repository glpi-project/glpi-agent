package GLPI::Agent::Task::Inventory::MacOS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

our $runAfter = ["GLPI::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME eq 'darwin';
}

sub doInventory {}

1;
