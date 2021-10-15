package GLPI::Agent::Task::Inventory::Generic::PCI::Sounds;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "sound";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $sound (_getSounds(logger => $logger)) {
        $inventory->addEntry(
            section => 'SOUNDS',
            entry   => $sound
        );
    }
}

sub _getSounds {
    my @sounds;

    foreach my $device (getPCIDevices(@_)) {
        next unless $device->{NAME} =~ /audio/i;
        push @sounds, {
            NAME         => $device->{NAME},
            MANUFACTURER => $device->{MANUFACTURER},
            DESCRIPTION  => $device->{REV} && "rev $device->{REV}",
        };
    }

    return @sounds;
}

1;
