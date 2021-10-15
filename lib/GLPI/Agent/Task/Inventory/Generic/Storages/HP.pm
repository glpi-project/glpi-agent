package GLPI::Agent::Task::Inventory::Generic::Storages::HP;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Storages::HP;

our $runMeIfTheseChecksFailed = ['GLPI::Agent::Task::Inventory::Generic::Storages::HpWithSmartctl'];

sub isEnabled {
    # MSWin32 has its Win32::Storages::HP dedicated module
    return canRun('hpacucli') && OSNAME ne 'MsWin32';
}

sub doInventory {
    HpInventory(
        path => 'hpacucli',
        @_
    );
}

1;
