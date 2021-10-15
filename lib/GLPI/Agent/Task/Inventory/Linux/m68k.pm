package GLPI::Agent::Task::Inventory::Linux::m68k;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^m68k/ if $params{remote};
    return $Config{archname} =~ /^m68k/;
}

sub doInventory {
}

1;
