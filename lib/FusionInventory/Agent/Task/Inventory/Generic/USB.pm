package FusionInventory::Agent::Task::Inventory::Generic::USB;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Generic;

use constant    category    => "usb";

sub isEnabled {
    return canRun('lsusb');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $device (_getDevices(
        logger  => $params{logger},
        datadir => $params{datadir})
    ) {
        $inventory->addEntry(
            section => 'USBDEVICES',
            entry   => $device,
        );
    }
}

sub _getDevices {
    my @devices;

    foreach my $device (_getDevicesFromLsusb(@_)) {
        next unless $device->{PRODUCTID};
        next unless $device->{VENDORID};

        # ignore the USB Hub
        next if
            $device->{PRODUCTID} eq "0001" ||
            $device->{PRODUCTID} eq "0002" ;

        if (defined($device->{SERIAL}) && length($device->{SERIAL}) < 5) {
            $device->{SERIAL} = undef;
        }

        my $vendor = getUSBDeviceVendor(id => $device->{VENDORID}, @_);
        if ($vendor) {
            $device->{MANUFACTURER} = $vendor->{name};

            my $entry = $vendor->{devices}->{$device->{PRODUCTID}};
            if ($entry) {
                $device->{CAPTION} = $entry->{name};
            }
        }

        push @devices, $device;
    }

    return @devices;
}

sub _getDevicesFromLsusb {
    my $handle = getFileHandle(
        @_,
        command => 'lsusb -v',
    );

    return unless $handle;

    my @devices;
    my $device;

    while (my $line = <$handle>) {
        if ($line =~ /^$/) {
            push @devices, $device if $device;
            undef $device;
        } elsif ($line =~ /^\s*idVendor\s*0x(\w+)/i) {
            $device->{VENDORID} = $1;
        } elsif ($line =~ /^\s*idProduct\s*0x(\w+)/i) {
            $device->{PRODUCTID} = $1;
        } elsif ($line =~ /^\s*iSerial\s*\d+\s(\w+)/i) {
            $device->{SERIAL} = $1;
        } elsif ($line =~ /^\s*bInterfaceClass\s*(\d+)/i) {
            $device->{CLASS} = $1;
        } elsif ($line =~ /^\s*bInterfaceSubClass\s*(\d+)/i) {
            $device->{SUBCLASS} = $1;
        }
    }
    close $handle;
    push @devices, $device if $device;

    return @devices;
}

1;
