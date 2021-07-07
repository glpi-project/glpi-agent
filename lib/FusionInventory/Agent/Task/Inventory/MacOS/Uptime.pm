package FusionInventory::Agent::Task::Inventory::MacOS::Uptime;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::MacOS;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $arch = getFirstLine(
        logger  => $logger,
        command => 'uname -m'
    );
    my $boottime = getBootTime(logger => $logger)
        or return;
    my $uptime = time - $boottime;
    $inventory->setHardware({
        DESCRIPTION => "$arch/$uptime"
    });
}

1;
