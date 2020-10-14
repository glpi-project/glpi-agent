package FusionInventory::Agent::Task::Inventory::Generic::Storages::HP;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Storages::HP;

our $runMeIfTheseChecksFailed = ['FusionInventory::Agent::Task::Inventory::Generic::Storages::HpWithSmartctl'];

sub isEnabled {
    # MSWin32 has its Win32::Storages::HP dedicated module
    return canRun('hpacucli') && $OSNAME ne 'MsWin32';
}

sub doInventory {
    HpInventory(
        path => 'hpacucli',
        @_
    );
}

1;
