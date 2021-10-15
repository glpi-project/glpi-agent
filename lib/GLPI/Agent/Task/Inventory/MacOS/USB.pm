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
}

sub _getDevices {

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
        }
        getIODevices(class => 'IOUSBDevice', options => '-r -l -w0 -d1', @_);
}

1;
