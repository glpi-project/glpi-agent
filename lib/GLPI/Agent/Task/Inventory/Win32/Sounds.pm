package GLPI::Agent::Task::Inventory::Win32::Sounds;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools::Win32;
use GLPI::Agent::Tools::Generic;

use constant    category    => "sound";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my @sounds = getWMIObjects(
        class      => 'Win32_SoundDevice',
        properties => [ qw/
            Name Manufacturer Caption Description PNPDeviceID
        / ]
    );

    # Try to find better names from Win32_PnPEntity if possible
    my %pnp_names;
    if (@sounds) {
        my @pnp_ids = grep { defined $_ && length $_ } map { $_->{PNPDeviceID} } @sounds;
        if (@pnp_ids) {
            my $query = "SELECT DeviceID, Name FROM Win32_PnPEntity WHERE " .
                        join(" OR ", map { my $id = $_; $id =~ s/\\/\\\\/g; "DeviceID='$id'" } @pnp_ids);

            foreach my $pnp (getWMIObjects(query => $query, properties => [qw/DeviceID Name/])) {
                $pnp_names{$pnp->{DeviceID}} = $pnp->{Name} if $pnp->{DeviceID};
            }
        }
    }

    foreach my $object (@sounds) {

        my $pnp_name = $object->{PNPDeviceID} ? $pnp_names{$object->{PNPDeviceID}} : undef;

        my $name         = $object->{Name};
        my $manufacturer = $object->{Manufacturer};
        my $caption      = $pnp_name || $object->{Caption};

        if ($object->{PNPDeviceID}) {
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
                    if ($vendor->{devices}->{$device_id}) {
                        my $entry = $vendor->{devices}->{$device_id};
                        $caption = $subdevice_id && $entry->{subdevices}->{$subdevice_id} ?
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
                    if ($vendor->{devices}->{$device_id}) {
                        my $entry = $vendor->{devices}->{$device_id};
                        $caption = $entry->{name} if $entry->{name};
                    }
                }
            }
        }

        $inventory->addEntry(
            section => 'SOUNDS',
            entry   => {
                NAME         => $name,
                CAPTION      => $caption,
                MANUFACTURER => $manufacturer,
                DESCRIPTION  => $object->{Description},
            }
        );
    }
}

1;
