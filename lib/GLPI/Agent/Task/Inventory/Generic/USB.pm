package GLPI::Agent::Task::Inventory::Generic::USB;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

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

        if (defined($device->{SERIAL}) && length($device->{SERIAL}) < 5) {
            $device->{SERIAL} = undef;
        }

        my $vendor = getUSBDeviceVendor(id => $device->{VENDORID}, @_);
        if ($vendor) {
            $device->{MANUFACTURER} = $vendor->{name};

            my $entry = $vendor->{devices}->{$device->{PRODUCTID}};
            if ($entry) {
                $device->{CAPTION} = $device->{NAME} = $entry->{name};
            }
        }

        push @devices, $device;
    }

    return @devices;
}

sub _getDevicesFromLsusb {
    my (%params) = (
        command => 'lsusb -v',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @devices;
    my $device;
    my ($hub, $selfpowered);

    foreach my $line (@lines) {
        if ($line =~ /^$/) {
            # Ignore any self-powered hub considering they are the embedded usb support hardware
            push @devices, $device if $device && !($hub && $selfpowered);
            undef $device;
            undef $hub;
            undef $selfpowered;
        } elsif ($line =~ /^\s*idVendor\s*0x(\w+)/i) {
            $device->{VENDORID} = $1;
        } elsif ($line =~ /^\s*idProduct\s*0x(\w+)/i) {
            $device->{PRODUCTID} = $1;
        } elsif ($line =~ /^\s*iProduct\s+\d+\s+(.*)$/i) {
            my $name = trimWhitespace(getSanitizedString($1));
            $device->{NAME} = $name unless empty($name);
        } elsif ($line =~ /^\s*iManufacturer\s+\d+\s+(.*)$/i) {
            my $manufacturer = trimWhitespace(getSanitizedString($1));
            $device->{MANUFACTURER} = $manufacturer unless empty($manufacturer);
        } elsif ($line =~ /^\s*iSerial\s*\d+\s(.*)$/i) {
            my $iSerial = trimWhitespace($1);
            # 1. Support manufacturers wrongly using iSerial with fields definition
            # 2. Don't include serials with colons as they seems to be an internal id for hub layers
            if ($iSerial =~ /S\/N:([^: ]+)/) {
                $device->{SERIAL} = $1;
            } elsif (!empty($iSerial) && $iSerial !~ /:/) {
                $device->{SERIAL} = $iSerial;
            }
        } elsif ($line =~ /^\s*bInterfaceClass\s*(\d+)/i) {
            $device->{CLASS} = $1;
        } elsif ($line =~ /^\s*bInterfaceSubClass\s*(\d+)/i) {
            $device->{SUBCLASS} = $1;
        } elsif ($line =~ /^\s*bDeviceClass\s*9\s+Hub/i) {
            $hub = 1;
        } elsif ($line =~ /^Device Status:\s*(0x[0-9a-f]{4})/i) {
            $selfpowered = hex($1) & 1;
        }
    }
    push @devices, $device if $device && !($hub && $selfpowered);

    return @devices;
}

1;
