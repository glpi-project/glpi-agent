package GLPI::Agent::Task::Inventory::Linux::SPARC;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^sparc/ if $params{remote};
    return $Config{archname} =~ /^sparc/;
};

sub doInventory {
}

1;
