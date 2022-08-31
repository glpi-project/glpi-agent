package GLPI::Agent::Task::Inventory::HPUX::Controllers;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "controller";

sub isEnabled {
    return canRun('ioscan');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $type (qw/ext_bus fc psi/) {
        foreach my $controller (_getControllers(
            command => "ioscan -kFC $type",
            logger  => $logger
        )) {
            $inventory->addEntry(
                section => 'CONTROLLERS',
                entry   => $controller
            );
        }
    }
}

sub _getControllers {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @controllers;
    foreach my $line (@lines) {
        my @info = split(/:/, $line);
        push @controllers, {
            TYPE => $info[17]
        };
    }

    return @controllers;
}

1;
