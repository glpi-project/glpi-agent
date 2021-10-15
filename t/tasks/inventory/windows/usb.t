#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More;
use UNIVERSAL::require;

use GLPI::Agent::Inventory;
use GLPI::Test::Utils;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

Test::NoWarnings->use();

GLPI::Agent::Task::Inventory::Win32::USB->require();

my %tests = (
    7 => [
        {
            NAME         => 'Integrated Rate Matching Hub',
            CAPTION      => 'Integrated Rate Matching Hub',
            MANUFACTURER => 'Intel Corp.',
            VENDORID     => '8087',
            PRODUCTID    => '0024',
        },
        {
            NAME         => 'Integrated Rate Matching Hub',
            CAPTION      => 'Integrated Rate Matching Hub',
            MANUFACTURER => 'Intel Corp.',
            VENDORID     => '8087',
            PRODUCTID    => '0024',
        },
        {
            NAME         => 'Bluetooth Adapter',
            CAPTION      => 'Bluetooth Adapter',
            MANUFACTURER => 'ASUSTek Computer, Inc.',
            VENDORID     => '0B05',
            PRODUCTID    => '179C',
        },
        {
            NAME         => 'QuickCam Ultra Vision',
            CAPTION      => 'QuickCam Ultra Vision',
            MANUFACTURER => 'Logitech, Inc.',
            SERIAL       => '6BE882AB',
            VENDORID     => '046D',
            PRODUCTID    => '08C9',

        },
        {
            NAME         => 'Premium Optical Wheel Mouse (M-BT58)',
            CAPTION      => 'Premium Optical Wheel Mouse (M-BT58)',
            MANUFACTURER => 'Logitech, Inc.',
            VENDORID     => '046D',
            PRODUCTID    => 'C03E'
        },
        {
            NAME         => 'iTouch Composite',
            CAPTION      => 'iTouch Composite',
            MANUFACTURER => 'Logitech, Inc.',
            VENDORID     => '046D',
            PRODUCTID    => 'C30A',
        },
    ],
    xppro2 => [
        {
            MANUFACTURER => 'Cherry GmbH',
            NAME         => 'Concentrador USB genérico',
            CAPTION      => 'Concentrador USB genérico',
            VENDORID     => '046A',
            PRODUCTID    => '0009'
        },
        {
            MANUFACTURER => 'Cherry GmbH',
            NAME         => 'Dispositivo compuesto USB',
            CAPTION       => 'Dispositivo compuesto USB',
            VENDORID     => '046A',
            PRODUCTID    => '0019'
        },
        {
            CAPTION      => 'SmartTerminal XX44',
            MANUFACTURER => 'Cherry GmbH',
            NAME         => 'SmartTerminal XX44',
            CAPTION      => 'SmartTerminal XX44',
            VENDORID     => '046A',
            PRODUCTID    => '002D'
        },
        {
            CAPTION      => 'Printing Support',
            MANUFACTURER => 'HP, Inc',
            NAME         => 'Printing Support',
            CAPTION      => 'Printing Support',
            SERIAL       => 'JV40VNJ',
            VENDORID     => '03F0',
            PRODUCTID    => '3A17'
        },
        {
            CAPTION      => 'HL-5250DN Printer',
            MANUFACTURER => 'Brother Industries, Ltd',
            NAME         => 'HL-5250DN Printer',
            CAPTION      => 'HL-5250DN Printer',
            SERIAL       => 'J5J126789',
            VENDORID     => '04F9',
            PRODUCTID    => '002B'
        },
        {
            CAPTION      => 'LaserJet P2015 series',
            MANUFACTURER => 'HP, Inc',
            NAME         => 'LaserJet P2015 series',
            CAPTION      => 'LaserJet P2015 series',
            SERIAL       => '00CNBW86S20B',
            VENDORID     => '03F0',
            PRODUCTID    => '3817'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new();

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::USB'
);

foreach my $test (keys %tests) {
    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    my @devices = GLPI::Agent::Task::Inventory::Win32::USB::_getDevices(datadir => './share');
    cmp_deeply(
        \@devices,
        $tests{$test},
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'USBDEVICES', entry => $_)
            foreach @devices;
    } "$test: registering";
}
