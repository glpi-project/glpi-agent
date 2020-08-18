package FusionInventory::Agent::Task::Inventory::Linux::ARM;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use Config;

use FusionInventory::Agent::Tools;

sub isEnabled {
    return Uname("-m") =~ /^arm|aarch64/ if $FusionInventory::Agent::Tools::remote;
    return $Config{archname} =~ /^arm/;
}

sub doInventory {
}

1;
