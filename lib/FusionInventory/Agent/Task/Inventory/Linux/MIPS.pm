package FusionInventory::Agent::Task::Inventory::Linux::MIPS;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use Config;

use FusionInventory::Agent::Tools;

sub isEnabled {
    return Uname("-m") =~ /^mips/ if $FusionInventory::Agent::Tools::remote;
    return $Config{archname} =~ /^mips/;
}

sub doInventory {
}

1;
