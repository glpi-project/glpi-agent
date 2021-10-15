package FusionInventory::Agent::Task::Inventory::Generic::Softwares;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use constant    category    => "software";

sub isEnabled {
    return 1;
}

sub doInventory {}

1;
