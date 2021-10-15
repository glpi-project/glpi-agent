package GLPI::Agent::Task::Inventory::Win32;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

our $runAfter = ["GLPI::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME eq 'MSWin32';
}

sub doInventory {

}

1;
