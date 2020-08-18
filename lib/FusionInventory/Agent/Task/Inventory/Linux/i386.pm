package FusionInventory::Agent::Task::Inventory::Linux::i386;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use Config;

use FusionInventory::Agent::Tools;

sub isEnabled {
    return Uname("-m") =~ /^(i\d86|x86_64)/ if $FusionInventory::Agent::Tools::remote;
    return $Config{archname} =~ /^(i\d86|x86_64)/;
}

sub doInventory {
}

1;
