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
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '8161'
        },
        {
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '8162'
        },
        {
            NAME         => 'Dell Wireless 365 Bluetooth Module',
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '254',
            PRODUCTID    => '8160',
            MANUFACTURER => 'Dell Computer Corp'
        },
        {
            NAME         => '5880',
            VENDORID     => '0a5c',
            SERIAL       => '0123456789ABCD',
            SUBCLASS     => '0',
            CLASS        => '254',
            PRODUCTID    => '5801',
            MANUFACTURER => 'Broadcom Corp'
        },
        {
            CLASS        => '0',
            SUBCLASS     => '0',
            VENDORID     => '1b96',
            PRODUCTID    => '0001'
        },
        {
            NAME         => 'Kensington PocketMouse Pro',
            VENDORID     => '047d',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '101f',
            MANUFACTURER => 'Kensington'
        }
    ],
    'ubuntu-bar-code-scanner' => [
        {
            NAME         => 'Symbol Bar Code Scanner',
            VENDORID     => '05e0',
            PRODUCTID    => '1200',
            SERIAL       => '28A1CC69D1D8AE4585EDA53F7CD6CB88',
            MANUFACTURER => 'ﾩSymbol Technologies, Inc, 2002'
        }
    ],
    'apc-ups' => [
        {
            NAME         => 'Smart-UPS 1000 RM FW:669.19.I USB FW:11.03',
            VENDORID     => '051d',
            PRODUCTID    => '0002',
            SUBCLASS     => '0',
            CLASS        => '3',
            SERIAL       => 'AS1042245614',
            MANUFACTURER => 'American Power Conversion'
        },
        {
            NAME         => 'Smart-UPS_1500 FW:UPS 03.5 / ID=1018',
            VENDORID     => '051d',
            PRODUCTID    => '0003',
            SUBCLASS     => '0',
            CLASS        => '3',
            SERIAL       => 'AS2032166823',
            MANUFACTURER => 'American Power Conversion'
        }
    ]
);

my %usb_tests = (
    'dell-xt2' => [
        {
            NAME         => re('^Integrated Keyboard'),
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '8161',
            MANUFACTURER => 'Dell Computer Corp.',
            CAPTION      => re('^Integrated Keyboard')
        },
        {
            NAME         => re('^Integrated Touchpad'),
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '8162',
            MANUFACTURER => 'Dell Computer Corp.',
            CAPTION      => re('^Integrated Touchpad')
        },
        {
            NAME         => re('^Wireless 365 Bluetooth'),
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '254',
            PRODUCTID    => '8160',
            MANUFACTURER => 'Dell Computer Corp.',
            CAPTION      => re('^Wireless 365 Bluetooth')
        },
        {
            NAME         => re('^BCM5880 Secure Applications Processor'),
            VENDORID     => '0a5c',
            SERIAL       => '0123456789ABCD',
            SUBCLASS     => '0',
            CLASS        => '254',
            PRODUCTID    => '5801',
            MANUFACTURER => 'Broadcom Corp.',
            CAPTION      => re('^BCM5880 Secure Applications Processor')
        },
        {
            NAME         => re('^Duosense Transparent Electromagnetic Digitizer'),
            VENDORID     => '1b96',
            SUBCLASS     => '0',
            CLASS        => '0',
            PRODUCTID    => '0001',
            MANUFACTURER => 'N-Trig',
            CAPTION      => re('^Duosense Transparent Electromagnetic Digitizer')
        },
        {
            NAME         => re('^PocketMouse Pro'),
            VENDORID     => '047d',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '101f',
            MANUFACTURER => 'Kensington',
            CAPTION      => re('^PocketMouse Pro')
        }
    ],
    'ubuntu-bar-code-scanner' => [
        {
            NAME         => re('Bar Code Scanner'),
            VENDORID     => '05e0',
            PRODUCTID    => '1200',
            MANUFACTURER => 'Symbol Technologies',
            SERIAL       => '28A1CC69D1D8AE4585EDA53F7CD6CB88',
            CAPTION      => re('^Bar Code Scanner')
        }
     ],
    'apc-ups' => [
        {
            NAME         => re('Uninterruptible Power Supply'),
            VENDORID     => '051d',
            PRODUCTID    => '0002',
            SUBCLASS     => '0',
            CLASS        => '3',
            SERIAL       => 'AS1042245614',
            MANUFACTURER => re('American Power Conversion'),
            CAPTION      => re('^Uninterruptible Power Supply')
        },
        {
            NAME         => re('UPS'),
            VENDORID     => '051d',
            PRODUCTID    => '0003',
            SUBCLASS     => '0',
            CLASS        => '3',
            SERIAL       => 'AS2032166823',
            MANUFACTURER => re('American Power Conversion'),
            CAPTION      => re('^UPS')
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
