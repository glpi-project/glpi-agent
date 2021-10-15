package GLPI::Agent::Task::Inventory::Linux::MIPS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^mips/ if $params{remote};
    return $Config{archname} =~ /^mips/;
}

sub doInventory {
}

1;
