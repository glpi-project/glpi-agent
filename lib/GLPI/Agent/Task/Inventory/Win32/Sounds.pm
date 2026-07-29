package GLPI::Agent::Task::Inventory::Win32::Sounds;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Win32;
use GLPI::Agent::Tools::Generic;

use constant    category    => "sound";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $sound (_getSoundDevices(logger => $logger)) {
        $inventory->addEntry(
            section => 'SOUNDS',
            entry   => $sound
        );
    }
}

sub _getSoundDevices {
    my (%params) = @_;

    my @sounds;
    my $PnPEntity;

    foreach my $object (getWMIObjects(
        class      => 'Win32_SoundDevice',
        properties => [ qw/
            Name Manufacturer Caption Description PNPDeviceID
        / ],
    )) {

        # We will try to find better names from Win32_PnPEntity
        unless ($PnPEntity) {
            $PnPEntity = {};
            foreach my $pnp (getWMIObjects(
                class => 'Win32_PnPEntity',
                properties => [qw/DeviceID Name/],
            )) {
                next if empty($pnp->{DeviceID}) || empty($pnp->{Name});
                $PnPEntity->{$pnp->{DeviceID}} = $pnp->{Name};
            }
        }

        my $name         = $object->{Name};
        my $manufacturer = $object->{Manufacturer};
        my $caption      = $object->{Caption};

        unless (empty($object->{PNPDeviceID})) {
            $name = $PnPEntity->{$object->{PNPDeviceID}}
                unless empty($PnPEntity->{$object->{PNPDeviceID}});
            if ($object->{PNPDeviceID} =~ /PCI\\VEN_(\S{4})&DEV_(\S{4})/) {
                my $vendor_id = lc($1);
                my $device_id = lc($2);
                my $subdevice_id;

                if ($object->{PNPDeviceID} =~ /&SUBSYS_(\S{4})(\S{4})/) {
                    $subdevice_id = lc($2 . ':' . $1);
                }

                my $vendor = getPCIDeviceVendor(id => $vendor_id, %params);
                if ($vendor) {
                    $manufacturer = $vendor->{name} if $vendor->{name};
                    my $entry = $vendor->{devices}->{$device_id};
                    if ($entry) {
                        $name = $subdevice_id && $entry->{subdevices}->{$subdevice_id} ?
                            $entry->{subdevices}->{$subdevice_id}->{name} :
                            $entry->{name};
                    }
                }
            } elsif ($object->{PNPDeviceID} =~ /USB\\VID_(\S{4})&PID_(\S{4})/) {
                my $vendor_id = lc($1);
                my $device_id = lc($2);

                my $vendor = getUSBDeviceVendor(id => $vendor_id, %params);
                if ($vendor) {
                    $manufacturer = $vendor->{name} if $vendor->{name};
                    my $entry = $vendor->{devices}->{$device_id};
                    $name = $entry->{name} if $entry && $entry->{name};
                }
            }
        }

        push @sounds, {
            NAME         => $name,
            CAPTION      => $caption,
            MANUFACTURER => $manufacturer,
            DESCRIPTION  => $object->{Description},
        };
    }

    return @sounds;
}

1;
