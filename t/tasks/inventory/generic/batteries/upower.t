#!/usr/bin/perl
use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Tools::Batteries;
use GLPI::Agent::Task::Inventory::Generic::Batteries::Upower;
use GLPI::Agent::Task::Inventory::Generic::Dmidecode::Battery;

my %testUpowerEnumerate = (
    'enumerate_1.txt' => [
        '/org/freedesktop/UPower/devices/battery_BAT1',
    ],
    'enumerate_2.txt' => [
        '/org/freedesktop/UPower/devices/battery_BAT0',
    ],
    'enumerate_4.txt' => [
        '/org/freedesktop/UPower/devices/battery_BAT0',
        '/org/freedesktop/UPower/devices/battery_hidpp_battery_0',
    ],
);

my %testUpowerInfos = (
    'infos_1.txt' => {
        NAME            => 'G71C000G7210',
        CAPACITY        => '51504',
        VOLTAGE         => '14800',
        CHEMISTRY       => 'lithium-ion',
        SERIAL          => 0,
        REAL_CAPACITY   => '39264',
    },
    'infos_2.txt' => {
        NAME            => 'DELL JHXPY53',
        CAPACITY        => '57532',
        VOLTAGE         => '8541',
        CHEMISTRY       => 'lithium-polymer',
        SERIAL          => 3682,
        MANUFACTURER    => 'SMP',
        REAL_CAPACITY   => '53405',
    },
    'infos_3.txt' => {
        NAME            => 'G750-59',
        CAPACITY        => '89208',
        VOLTAGE         => '15120',
        CHEMISTRY       => 'lithium-ion',
        MANUFACTURER    => 'ASUSTeK',
        SERIAL          => 0,
        REAL_CAPACITY   => '74496',
    },
    'infos_4.1.txt' => {
        NAME            => 'DELL XDY9K16',
        CAPACITY        => '54000',
        VOLTAGE         => '14827',
        CHEMISTRY       => 'lithium-polymer',
        MANUFACTURER    => 'SMP-COS3.66',
        SERIAL          => 3829,
        REAL_CAPACITY   => '54000',
    },
    'infos_4.2.txt' => {
        NAME            => 'Anywhere MX',
        CHEMISTRY       => undef,
        SERIAL          => '1017-9b-29-dd-8f',
    },
);

my %testUpowerMerged = (
    'toshiba_1' => {
        dmidecode   => 'dmidecode_1.txt',
        upowerlist => [ 'infos_1.txt' ],
        step1 => [],
        merged => [
            {
                NAME            => 'G71C000G7210',
                CAPACITY        => '51504',
                VOLTAGE         => '14800',
                CHEMISTRY       => 'lithium-ion',
                SERIAL          => 0,
                REAL_CAPACITY   => '39264'
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
                NAME            => 'DELL JHXPY53',
                CAPACITY        => '57532',
                VOLTAGE         => '8541',
                CHEMISTRY       => 'lithium-polymer',
                SERIAL          => 3682,
                MANUFACTURER    => 'SMP',
                DATE            => '10/11/2015',
                REAL_CAPACITY   => '53405'
            }
        ],
    },
    'dell_4' => {
        dmidecode => 'dmidecode_4.txt',
        upowerlist => [ 'infos_4.1.txt' ],
        step1 => [
            {
                NAME         => 'DELL XDY9K16',
                CAPACITY     => '54000',
                VOLTAGE      => '15000',
                CHEMISTRY    => 'Lithium Ion',
                SERIAL       => 3829,
                MANUFACTURER => 'SMP-COS3.66',
            }
        ],
        merged => [
            {
                NAME            => 'DELL XDY9K16',
                CAPACITY        => '54000',
                VOLTAGE         => '14827',
                CHEMISTRY       => 'lithium-polymer',
                SERIAL          => 3829,
                MANUFACTURER    => 'SMP-COS3.66',
                REAL_CAPACITY   => '54000'
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
    my @battNames = GLPI::Agent::Task::Inventory::Generic::Batteries::Upower::_getBatteriesNameFromUpower(
        file => 'resources/generic/batteries/upower/' . $test
    );
    cmp_deeply (
        \@battNames,
        $testUpowerEnumerate{$test},
        "$test: _getBatteriesNameFromUpower()"
    );
}

foreach my $test (keys %testUpowerInfos) {
    my $battery = GLPI::Agent::Task::Inventory::Generic::Batteries::Upower::_getBatteryFromUpower(
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
        GLPI::Agent::Task::Inventory::Generic::Dmidecode::Battery::_getBatteries(
            file => 'resources/generic/batteries/upower/' . $dmidecode
        );

    cmp_deeply(
        [ $list->list() ],
        $testUpowerMerged{$test}->{step1},
        "test $test: merge step 1"
    );

    foreach my $file (@{$testUpowerMerged{$test}->{upowerlist}}) {
        my $battery = GLPI::Agent::Task::Inventory::Generic::Batteries::Upower::_getBatteryFromUpower(
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
