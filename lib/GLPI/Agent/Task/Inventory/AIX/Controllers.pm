package GLPI::Agent::Task::Inventory::AIX::Controllers;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::AIX;

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
