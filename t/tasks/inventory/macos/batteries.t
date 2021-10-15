#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::MacOS::Batteries;

use English;

my %tests = (
    '10.11-system_profiler_SPPowerDataType.txt' => {
        SERIAL => 'C01437408B3F90MA2',
        CAPACITY => '6078',
        NAME => 'bq20z451',
        MANUFACTURER => 'DP',
        VOLTAGE => '7921'
    }
);

plan tests => 1
        + scalar (keys %tests);

my $resourcesPath = 'resources/macos/system_profiler/';
for my $fileName (keys %tests) {
    my $filePath = $resourcesPath . $fileName;
    my $battery = GLPI::Agent::Task::Inventory::MacOS::Batteries::_getBattery(
        file => $filePath
    );
    cmp_deeply(
        $battery,
        $tests{$fileName},
        "Battery information"
    );
}
