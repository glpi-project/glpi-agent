package FusionInventory::Agent::Task::Inventory::Linux::m68k;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use Config;

use FusionInventory::Agent::Tools;

sub isEnabled {
    return Uname("-m") =~ /^m68k/ if $FusionInventory::Agent::Tools::remote;
    return $Config{archname} =~ /^m68k/;
}

sub doInventory {
}

1;
