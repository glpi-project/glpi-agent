package FusionInventory::Agent::Task::Inventory::Linux::Distro;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {}

1;
