package GLPI::Agent::Task::Inventory::AccessLog;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

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
