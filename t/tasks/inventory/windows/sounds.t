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

GLPI::Agent::Task::Inventory::Win32::Sounds->require();

my %tests = (
    'logitech-h390' => [
        {
            CAPTION      => 'H390 headset with microphone',
            DESCRIPTION  => 'USB Audio Device',
            MANUFACTURER => 'Logitech, Inc.',
            NAME         => 'USB Audio Device',
        }
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new();

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::Sounds'
);

foreach my $test (keys %tests) {
    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    my $inventory_mock = GLPI::Agent::Inventory->new();
    GLPI::Agent::Task::Inventory::Win32::Sounds::doInventory(
        inventory => $inventory_mock,
        datadir   => './share',
    );

    cmp_deeply(
        $inventory_mock->getSection('SOUNDS'),
        $tests{$test},
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'SOUNDS', entry => $_)
            foreach @{$inventory_mock->getSection('SOUNDS') // []};
    } "$test: registering";
}
