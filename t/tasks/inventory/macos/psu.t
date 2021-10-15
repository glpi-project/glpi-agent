#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::MacOS::Psu;

use English;

my %tests = (
    'charging' => {
        SERIALNUMBER    => 'HD2J66XBVX2K',
        NAME            => '61W USB-C Power Adapter',
        MANUFACTURER    => 'Apple Inc.',
        PLUGGED         => 'Yes',
        STATUS          => 'Charging',
        POWER_MAX       => '60',
    },
    'charged' => {
        SERIALNUMBER    => 'HD2J66XBVX2K',
        NAME            => '61W USB-C Power Adapter',
        MANUFACTURER    => 'Apple Inc.',
        PLUGGED         => 'Yes',
        STATUS          => 'Not charging',
        POWER_MAX       => '60',
    },
);

plan tests => 1
        + 2*scalar (keys %tests);

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $filePath = "resources/macos/system_profiler/$test-SPPowerDataType";
    my $charger = GLPI::Agent::Task::Inventory::MacOS::Psu::_getCharger(
        file => $filePath
    );
    cmp_deeply(
        $charger,
        $tests{$test},
        "$test: system profiler parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'POWERSUPPLIES', entry => $charger);
    } "$test: registering";
}
