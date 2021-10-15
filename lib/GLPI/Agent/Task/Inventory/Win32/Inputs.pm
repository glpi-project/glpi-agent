package GLPI::Agent::Task::Inventory::Win32::Inputs;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

# Had never been tested.
use GLPI::Agent::Tools::Win32;

use constant    category    => "input";

my %mouseInterface = (
    1 =>  'Other',
    2 => 'Unknown',
    3 => 'Serial',
    4 => 'PS/2',
    5 => 'Infrared',
    6 => 'HP-HIL',
    7 => 'Bus Mouse',
    8 => 'ADB (Apple Desktop Bus)',
    160 => 'Bus Mouse DB-9',
    161 => 'Bus Mouse Micro-DIN',
    162 => 'USB',
);

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my %seen;
    my $inventory = $params{inventory};

    foreach my $object (getWMIObjects(
        class      => 'Win32_Keyboard',
        properties => [ qw/Name Caption Manufacturer Description Layout/ ]
    )) {
        my $input = {
            NAME         => $object->{Name},
            CAPTION      => $object->{Caption},
            MANUFACTURER => $object->{Manufacturer},
            DESCRIPTION  => $object->{Description},
            LAYOUT       => $object->{Layout},
        };

        # avoid duplicates
        next if $seen{$input->{NAME}}++;

        $inventory->addEntry(
            section => 'INPUTS',
            entry   => $input
        );
    }

    foreach my $object (getWMIObjects(
        class      => 'Win32_PointingDevice',
        properties => [ qw/Name Caption Manufacturer Description PointingType DeviceInterface/ ]
    )) {
        my $input = {
            NAME         => $object->{Name},
            CAPTION      => $object->{Caption},
            MANUFACTURER => $object->{Manufacturer},
            DESCRIPTION  => $object->{Description},
            POINTINGTYPE => $object->{PointingType},
            INTERFACE    => $mouseInterface{$object->{DeviceInterface}},
        };

        # avoid duplicates
        next if $seen{$input->{NAME}}++;

        $inventory->addEntry(
            section => 'INPUTS',
            entry   => $input
        );
    }

}

1;
