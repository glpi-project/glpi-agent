package GLPI::Agent::Task::Inventory::Win32::Modems;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools::Win32;

use constant    category    => "modem";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $object (getWMIObjects(
        class      => 'Win32_POTSModem',
        properties => [ qw/Name DeviceType Model Description/ ]
    )) {

        $inventory->addEntry(
            section => 'MODEMS',
            entry   => {
                NAME        => $object->{Name},
                TYPE        => $object->{DeviceType},
                MODEL       => $object->{Model},
                DESCRIPTION => $object->{Description},
            }
        );
    }
}

1;
