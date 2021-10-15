package FusionInventory::Agent::Task::Inventory::AccessLog;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

use constant    category    => "accesslog";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $date = getFormatedLocalTime(time());

    $inventory->setAccessLog ({
        LOGDATE => $date
    });
}

1;
