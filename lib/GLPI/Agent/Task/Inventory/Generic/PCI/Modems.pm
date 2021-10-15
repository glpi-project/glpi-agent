package FusionInventory::Agent::Task::Inventory::Generic::PCI::Modems;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Generic;

use constant    category    => "modem";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $modem (_getModems(logger => $logger)) {
        $inventory->addEntry(
            section => 'MODEMS',
            entry   => $modem
        );
    }
}

sub _getModems {
    my @modems;

    foreach my $device (getPCIDevices(@_)) {
        next unless $device->{NAME} =~ /modem/i;
        push @modems, {
            DESCRIPTION => $device->{NAME},
            NAME        => $device->{MANUFACTURER},
        };
    }

    return @modems;
}

1;
