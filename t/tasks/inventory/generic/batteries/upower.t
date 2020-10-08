#!/usr/bin/perl
use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use FusionInventory::Agent::Tools::Batteries;
use FusionInventory::Agent::Task::Inventory::Generic::Batteries::Upower;
use FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Battery;

my %testUpowerEnumerate = (
    'enumerate_1.txt' => [
        '/org/freedesktop/UPower/devices/battery_BAT1',
    ],
    'enumerate_2.txt' => [
        '/org/freedesktop/UPower/devices/battery_BAT0',
    ],
);

my %testUpowerInfos = (
    'infos_1.txt' => {
        NAME         => 'G71C000G7210',
        CAPACITY     => '51,504 Wh',
        VOLTAGE      => '14,8 V',
        CHEMISTRY    => 'lithium-ion',
        SERIAL       => 0,
    },
    'infos_2.txt' => {
        NAME         => 'DELL JHXPY53',
        CAPACITY     => '57,532 Wh',
        VOLTAGE      => '8,541 V',
        CHEMISTRY    => 'lithium-polymer',
        SERIAL       => 3682,
        MANUFACTURER => 'SMP',
    },
    'infos_3.txt' => {
        NAME         => 'G750-59',
        CAPACITY     => '89,208 Wh',
        VOLTAGE      => '15,12 V',
        CHEMISTRY    => 'lithium-ion',
        MANUFACTURER => 'ASUSTeK',
        SERIAL       => 0,
    },
);

my %testUpowerMerged = (
    'toshiba_1' => {
        dmidecode   => 'dmidecode_1.txt',
        upowerlist => [ 'infos_1.txt' ],
        step1 => [],
        merged => [
            {
                NAME         => 'G71C000G7210',
                CAPACITY     => '51,504 Wh',
                VOLTAGE      => '14,8 V',
                CHEMISTRY    => 'lithium-ion',
                SERIAL       => 0,
            }
        ],
    },
    'dell_2' => {
        dmidecode => 'dmidecode_2.txt',
        upowerlist => [ 'infos_2.txt' ],
        step1 => [
            {
                NAME         => 'DELL JHXPY53',
                CAPACITY     => '57530',
                VOLTAGE      => '7600',
                CHEMISTRY    => 'LiP',
                SERIAL       => 3682,
                MANUFACTURER => 'SMP',
                DATE         => '10/11/2015',
            }
        ],
        merged => [
            {
                NAME         => 'DELL JHXPY53',
                CAPACITY     => '57,532 Wh',
                VOLTAGE      => '8,541 V',
                CHEMISTRY    => 'lithium-polymer',
                SERIAL       => 3682,
                MANUFACTURER => 'SMP',
                DATE         => '10/11/2015',
            }
        ],
    },
);

plan tests =>
    scalar (keys %testUpowerEnumerate) +
    scalar (keys %testUpowerInfos) +
    2 * scalar (keys %testUpowerMerged) +
    1;

foreach my $test (keys %testUpowerEnumerate) {
    my @battNames = FusionInventory::Agent::Task::Inventory::Generic::Batteries::Upower::_getBatteriesNameFromUpower(
        file => 'resources/generic/batteries/upower/' . $test
    );
    cmp_deeply (
        \@battNames,
        $testUpowerEnumerate{$test},
        "$test: _getBatteriesNameFromUpower()"
    );
}

foreach my $test (keys %testUpowerInfos) {
    my $battery = FusionInventory::Agent::Task::Inventory::Generic::Batteries::Upower::_getBatteryFromUpower(
        file => 'resources/generic/batteries/upower/' . $test
    );
    cmp_deeply(
        $battery,
        $testUpowerInfos{$test},
        "$test: _getBatteriesFromUpower()"
    );
}

foreach my $test (keys %testUpowerMerged) {
    my $list = Inventory::Batteries->new();
    my $dmidecode = $testUpowerMerged{$test}->{dmidecode};

    # Prepare batteries list like it should be after dmidecode passed
    map { $list->add($_) }
        FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Battery::_getBatteries(
            file => 'resources/generic/batteries/upower/' . $dmidecode
        );

    cmp_deeply(
        [ $list->list() ],
        $testUpowerMerged{$test}->{step1},
        "test $test: merge step 1"
    );

    foreach my $file (@{$testUpowerMerged{$test}->{upowerlist}}) {
        my $battery = FusionInventory::Agent::Task::Inventory::Generic::Batteries::Upower::_getBatteryFromUpower(
            file => 'resources/generic/batteries/upower/' . $file
        );
        $list->merge($battery);
    };

    cmp_deeply(
        [ $list->list() ],
        $testUpowerMerged{$test}->{merged},
        "test $test: merged"
    );
}
