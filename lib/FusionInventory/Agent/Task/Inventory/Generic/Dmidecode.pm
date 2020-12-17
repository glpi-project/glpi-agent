package FusionInventory::Agent::Task::Inventory::Generic::Dmidecode;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Generic;

sub isEnabled {
    my (%params) = @_;

    # don't run dmidecode on Win2003
    # http://forge.fusioninventory.org/issues/379
    if (OSNAME eq 'MSWin32') {
        return 0 if $params{remote};
        Win32->require();
        return if Win32::GetOSName() eq 'Win2003';
    }

    return canRun('dmidecode') && getDmidecodeInfos();
}

sub doInventory {}

1;
