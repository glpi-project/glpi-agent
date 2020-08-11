package FusionInventory::Agent::Task::Inventory::AIX;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME eq 'aix';
}

sub doInventory {}

1;
