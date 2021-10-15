package GLPI::Agent::Task::Inventory::Linux;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

our $runAfter = ["GLPI::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME eq 'linux';
}

sub doInventory {}

1;
