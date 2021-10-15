package GLPI::Agent::Task::Inventory::Linux::Alpha;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^alpha/ if $params{remote};
    return $Config{archname} =~ /^alpha/;
};

sub doInventory {
}

1;
