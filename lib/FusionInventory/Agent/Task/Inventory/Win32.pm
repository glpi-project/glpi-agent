package FusionInventory::Agent::Task::Inventory::Win32;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME eq 'MSWin32';
}

sub isEnabledForRemote {
    return OSNAME eq 'MSWin32';
}

sub doInventory {

}

1;
