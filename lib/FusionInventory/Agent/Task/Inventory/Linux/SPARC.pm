package FusionInventory::Agent::Task::Inventory::Linux::SPARC;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use Config;

use FusionInventory::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^sparc/ if $params{remote};
    return $Config{archname} =~ /^sparc/;
};

sub doInventory {
}

1;
