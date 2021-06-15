package FusionInventory::Agent::Task::Inventory::Generic::Remote_Mgmt;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use constant    category    => "remote_mgmt";

sub isEnabled {
    my (%params) = @_;
    return 1;
}

sub isEnabledForRemote {
    my (%params) = @_;
    return 1;
}

sub doInventory {
}

1;
