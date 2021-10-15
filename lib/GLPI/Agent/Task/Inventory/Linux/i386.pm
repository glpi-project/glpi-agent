package GLPI::Agent::Task::Inventory::Linux::i386;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^(i\d86|x86_64)/ if $params{remote};
    return $Config{archname} =~ /^(i\d86|x86_64)/;
}

sub doInventory {
}

1;
