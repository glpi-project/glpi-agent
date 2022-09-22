package GLPI::Agent::Task::Inventory::Generic::PCI::Videos;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "video";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $video (_getVideos(logger => $logger)) {
        $inventory->addEntry(
            section => 'VIDEOS',
            entry   => $video
        );
    }
}

sub _getVideos {
    my @videos;

    foreach my $device (getPCIDevices(@_)) {
        next unless $device->{NAME} =~ /graphics|vga|video|display|3D controller/i;

        push @videos, {
            CHIPSET => $device->{NAME},
            NAME    => $device->{MANUFACTURER},
        };
    }

    return @videos;
}

1;
