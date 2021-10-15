package FusionInventory::Agent::Task::Inventory::Linux;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME eq 'linux';
}

sub doInventory {}

1;
