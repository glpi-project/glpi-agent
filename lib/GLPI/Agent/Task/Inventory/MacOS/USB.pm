package GLPI::Agent::Task::Inventory::MacOS::USB;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::MacOS;

use constant    category    => "usb";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $seen;

    foreach my $device (_getDevices(logger => $logger)) {
        # avoid duplicates
        next if $device->{SERIAL} && $seen->{$device->{SERIAL}}++;
        $inventory->addEntry(
            section => 'USBDEVICES',
            entry   => $device,
        );
    }

    foreach my $device (_getThunderbolt(logger => $logger)) {
        # avoid duplicates
        next if empty($device->{SERIAL}) || $seen->{$device->{SERIAL}}++;
        $inventory->addEntry(
            section => 'USBDEVICES',
            entry   => $device,
        );
    }
}

sub _getDevices {
    my (%params) = @_;

    return
        map {
            {
                VENDORID  => dec2hex($_->{'idVendor'}),
                PRODUCTID => dec2hex($_->{'idProduct'}),
                SERIAL    => $_->{'USB Serial Number'},
                NAME      => $_->{'USB Product Name'},
                CLASS     => $_->{'bDeviceClass'},
                SUBCLASS  => $_->{'bDeviceSubClass'}
            }
        } getIODevices(
            class   => 'IOUSBDevice',
            options => '-r -l -w0 -d1',
            %params
        );
}

sub _getThunderbolt {
    my (%params) = @_;

    my $thunderbolt = getSystemProfilerInfos(
        type    => 'SPThunderboltDataType',
        format  => 'json',
        %params
    );

    return unless ref($thunderbolt) eq 'ARRAY';

    my @devices;
    foreach my $bus (@{$thunderbolt}) {
        next unless $bus->{_items};
        foreach my $item (@{$bus->{_items}}) {
            my $device = {
                NAME            => $item->{_name},
                MANUFACTURER    => $item->{vendor_name_key},
                CAPTION         => $item->{device_name_key},
            };
            my $receptable = $item->{receptacle_upstream_ambiguous_tag}
                or next;
            $device->{SERIAL} = $receptable->{cm_asn_key}
                or next;
            push @devices, $device;
        }
    }

    return @devices;
}

1;
