package FusionInventory::Agent::Task::Inventory::Linux::Alpha;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use Config;

use FusionInventory::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^alpha/ if $params{remote};
    return $Config{archname} =~ /^alpha/;
};

sub doInventory {
}

1;
