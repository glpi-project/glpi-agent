package FusionInventory::Agent::Task::Inventory::HPUX;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Generic"];

sub isEnabled  {
    return OSNAME eq 'hpux';
}

sub doInventory {}

1;
