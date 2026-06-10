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
use Test::NoWarnings;
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

# Required to make USB mock work correctly on Linux (same pattern as usb.t)
our $OSNAME = "MSWin32";

GLPI::Agent::Task::Inventory::Win32::Sounds->require();
GLPI::Agent::Task::Inventory::Win32::USB->require();

my %tests = (
    'logitech-h390' => {
        sounds => [
            {
                CAPTION      => 'USB Audio Device',
                DESCRIPTION  => 'USB Audio Device',
                MANUFACTURER => 'Logitech, Inc.',
                NAME         => 'H390 headset with microphone',
            }
        ],
        usbdevices => [
            {
                CAPTION      => 'H390 headset with microphone',
                MANUFACTURER => 'Logitech, Inc.',
                NAME         => 'H390 headset with microphone',
                PRODUCTID    => '0A8F',
                VENDORID     => '046D',
            }
        ],
    },
);

# 2 assertions (parsing + registering) per section (SOUNDS + USBDEVICES) per test, plus NoWarnings
plan tests => (4 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new();

my $sounds_module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::Sounds'
);

# Mirror the mock pattern from usb.t: mock getWMIObjects on both the USB
# module package and GLPI::Agent::Tools::Win32 (the thread-safe wrapper)
my @usb_mocks = map { Test::MockModule->new($_) } qw(
    GLPI::Agent::Task::Inventory::Win32::USB
    GLPI::Agent::Tools::Win32
);

foreach my $test (keys %tests) {
    my $expected = $tests{$test};

    $sounds_module->mock('getWMIObjects', mockGetWMIObjects($test));
    map { $_->mock('getWMIObjects',  mockGetWMIObjects($test)) } @usb_mocks;
    map { $_->mock('_getWMIObjects', mockGetWMIObjects($test)) } @usb_mocks;

    my $inventory_mock = GLPI::Agent::Inventory->new();

    GLPI::Agent::Task::Inventory::Win32::Sounds::doInventory(
        inventory => $inventory_mock,
        datadir   => './share',
    );

    # Call _getDevices directly (same pattern as usb.t) so the mock is
    # correctly intercepted at the GLPI::Agent::Tools::Win32 level
    my @usb_devices = GLPI::Agent::Task::Inventory::Win32::USB::_getDevices(
        datadir => './share',
    );
    $inventory_mock->addEntry(section => 'USBDEVICES', entry => $_)
        foreach @usb_devices;

    # Check SOUNDS — NAME and MANUFACTURER resolved from usb.ids
    cmp_deeply(
        $inventory_mock->getSection('SOUNDS'),
        $expected->{sounds},
        "$test: SOUNDS parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'SOUNDS', entry => $_)
            foreach @{$inventory_mock->getSection('SOUNDS') // []};
    } "$test: SOUNDS registering";

    # Check USBDEVICES — NAME and MANUFACTURER must match SOUNDS,
    # confirming both sections resolve identically from usb.ids
    cmp_deeply(
        $inventory_mock->getSection('USBDEVICES'),
        $expected->{usbdevices},
        "$test: USBDEVICES parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'USBDEVICES', entry => $_)
            foreach @{$inventory_mock->getSection('USBDEVICES') // []};
    } "$test: USBDEVICES registering";
}
