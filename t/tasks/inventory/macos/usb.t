#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::MacOS::USB;

my %tests = (
    IOUSBDevice1 => [
        {
            CLASS     => '0',
            NAME      => 'Apple Internal Keyboard / Trackpad',
            SERIAL    => undef,
            SUBCLASS  => '0',
            VENDORID  => '0x5ac',
            PRODUCTID => '0x21b'
        },
        {
            CLASS     => '0',
            NAME      => 'IR Receiver',
            SERIAL    => undef,
            SUBCLASS  => '0',
            VENDORID  => '0x5ac',
            PRODUCTID => '0x8240'
        },
        {
            CLASS     => '224',
            NAME      => 'Bluetooth USB Host Controller',
            SERIAL    => undef,
            SUBCLASS  => '1',
            VENDORID  => '0x5ac',
            PRODUCTID => '0x8205'
        },
        {
            CLASS     => '255',
            NAME      => 'Built-in iSight',
            SERIAL    => undef,
            SUBCLASS  => '255',
            VENDORID  => '0x5ac',
            PRODUCTID => '0x8501'
        },
        {
            CLASS     => '0',
            NAME      => 'Flash Disk',
            SERIAL    => '16270078C5C90000',
            SUBCLASS  => '0',
            VENDORID  => '0x1976',
            PRODUCTID => '0x6025'
        }
    ],
    IOUSBDevice2 => [
        {
            CLASS     => '0',
            NAME      => 'NetScroll + Mini Traveler',
            SERIAL    => undef,
            SUBCLASS  => '0',
            VENDORID  => '0x458',
            PRODUCTID => '0x36'
        },
        {
            CLASS     => '224',
            NAME      => 'Bluetooth USB Host Controller',
            SERIAL    => undef,
            SUBCLASS  => '1',
            VENDORID  => '0x5ac',
            PRODUCTID => '0x8206'
        },
        {
            CLASS     => '0',
            NAME      => 'Apple Keyboard',
            SERIAL    => undef,
            SUBCLASS  => '0',
            VENDORID  => '0x5ac',
            PRODUCTID => '0x221'
        },
        {
            CLASS     => '0',
            NAME      => 'IR Receiver',
            SERIAL    => undef,
            SUBCLASS  => '0',
            VENDORID  => '0x5ac',
            PRODUCTID => '0x8242'
        },
        {
            CLASS     => '0',
            NAME      => 'LaCie Device',
            SERIAL    => '6E7A5FFFFFFF',
            SUBCLASS  => '0',
            VENDORID  => '0x59f',
            PRODUCTID => '0x102a'
        },
        {
            CLASS     => '239',
            NAME      => 'Built-in iSight',
            SERIAL    => '6067E773DA9722F4 (03.01)',
            SUBCLASS  => '2',
            VENDORID  => '0x5ac',
            PRODUCTID => '0x8502'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/macos/ioreg/$test";
    my @devices = GLPI::Agent::Task::Inventory::MacOS::USB::_getDevices(file => $file);
    cmp_deeply(\@devices, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'USBDEVICES', entry => $_)
            foreach @devices;
    } "$test: registering";
}
