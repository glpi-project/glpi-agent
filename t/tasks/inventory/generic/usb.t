#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::USB;

my %lsusb_tests = (
    'dell-xt2' => [
        {
            VENDORID   => '1d6b',
            SUBCLASS   => '0',
            CLASS      => '9',
            PRODUCTID  => '0001',
            SERIAL     => '0000',
        },
        {
            VENDORID   => '0a5c',
            SUBCLASS   => '0',
            CLASS      => '9',
            PRODUCTID  => '4500',
        },
        {
            VENDORID   => '413c',
            SUBCLASS   => '1',
            CLASS      => '3',
            PRODUCTID  => '8161',
        },
        {
            VENDORID   => '413c',
            SUBCLASS   => '1',
            CLASS      => '3',
            PRODUCTID  => '8162',
        },
        {
            VENDORID   => '413c',
            SUBCLASS   => '1',
            CLASS      => '254',
            PRODUCTID  => '8160',
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            VENDORID  => '0a5c',
            SERIAL    => '0123456789ABCD',
            SUBCLASS  => '0',
            CLASS     => '254',
            PRODUCTID => '5801',
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            CLASS     => '0',
            SUBCLASS  => '0',
            VENDORID  => '1b96',
            PRODUCTID => '0001'
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            VENDORID  => '047d',
            SUBCLASS  => '1',
            CLASS     => '3',
            PRODUCTID => '101f',
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0002'
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0002'
        }
    ]
);

my %usb_tests = (
    'dell-xt2' => [
        {
            VENDORID     => '0a5c',
            SUBCLASS     => '0',
            CLASS        => '9',
            PRODUCTID    => '4500',
            MANUFACTURER => 'Broadcom Corp.',
            CAPTION      => re('^BCM2046B1 USB 2.0 Hub')
        },
        {
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '8161',
            MANUFACTURER => 'Dell Computer Corp.',
            CAPTION      => re('^Integrated Keyboard')
        },
        {
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '8162',
            MANUFACTURER => 'Dell Computer Corp.',
            CAPTION      => re('^Integrated Touchpad')
        },
        {
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '254',
            PRODUCTID    => '8160',
            MANUFACTURER => 'Dell Computer Corp.',
            CAPTION      => re('^Wireless 365 Bluetooth')
        },
        {
            VENDORID     => '0a5c',
            SERIAL       => '0123456789ABCD',
            SUBCLASS     => '0',
            CLASS        => '254',
            PRODUCTID    => '5801',
            MANUFACTURER => 'Broadcom Corp.',
            CAPTION      => re('^BCM5880 Secure Applications Processor')
        },
        {
            VENDORID     => '047d',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '101f',
            MANUFACTURER => 'Kensington',
            CAPTION      => re('^PocketMouse Pro')
        }
    ]
);

plan tests =>
    (scalar keys %lsusb_tests) +
    (2 * scalar keys %usb_tests)   +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %lsusb_tests) {
    my $file = "resources/generic/lsusb/$test";
    my @devices = GLPI::Agent::Task::Inventory::Generic::USB::_getDevicesFromLsusb(file => $file);
    cmp_deeply(\@devices, $lsusb_tests{$test}, "$test: lsusb parsing");
}

foreach my $test (keys %usb_tests) {
    my $file = "resources/generic/lsusb/$test";
    my @devices = GLPI::Agent::Task::Inventory::Generic::USB::_getDevices(file => $file, datadir => './share');
    cmp_deeply(\@devices, $usb_tests{$test}, "$test: usb devices retrieval");
    lives_ok {
        $inventory->addEntry(section => 'USBDEVICES', entry => $_)
            foreach @devices;
    } "$test: registering";
}
