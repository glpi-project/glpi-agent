package FusionInventory::Agent::Task::Inventory::AIX::Controllers;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::AIX;

use constant    category    => "controller";

sub isEnabled {
    return canRun('lsdev');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $controller (_getControllers(
        logger  => $logger,
    )) {
        $inventory->addEntry(
            section => 'CONTROLLERS',
            entry   => $controller
        );
    }
}

sub _getControllers {
    my @adapters = getAdaptersFromLsdev(@_);

    my @controllers;
    foreach my $adapter (@adapters) {
        push @controllers, {
            NAME => $adapter->{NAME},
        };
    }

    return @controllers;
}

1;
