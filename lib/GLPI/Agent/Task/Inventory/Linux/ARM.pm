package GLPI::Agent::Task::Inventory::Linux::ARM;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^arm|aarch64/ if $params{remote};
    return $Config{archname} =~ /^arm/;
}

sub doInventory {
}

1;
