package GLPI::Agent::Task::Inventory::MacOS::Uptime;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::MacOS;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $arch = Uname("-m");
    my $boottime = getBootTime(logger => $logger)
        or return;
    my $uptime = time - $boottime;
    $inventory->setHardware({
        DESCRIPTION => "$arch/$uptime"
    });
}

1;
