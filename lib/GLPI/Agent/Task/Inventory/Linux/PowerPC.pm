package GLPI::Agent::Task::Inventory::Linux::PowerPC;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^(ppc|powerpc)/ if $params{remote};
    return $Config{archname} =~ /^(ppc|powerpc)/;
}

sub doInventory {
}

1;
