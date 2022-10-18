#!/usr/bin/perl
use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Tools::Batteries;
use GLPI::Agent::Task::Inventory::Win32::Batteries;
use GLPI::Agent::Task::Inventory::Generic::Dmidecode::Battery;

my %testPowercfgInfos = (
    'windows-10-notebook' => [
        {
            NAME            => '00HW023',
            CAPACITY        => '23540',
            CHEMISTRY       => 'LiP',
            SERIAL          => '541',
            MANUFACTURER    => 'SMP',
            REAL_CAPACITY   => '19450',
        },
        {
            NAME            => '01AV406',
            CAPACITY        => '26060',
            CHEMISTRY       => 'LiP',
            SERIAL          => '3319',
            MANUFACTURER    => 'SMP',
            REAL_CAPACITY   => '17860',
        }
    ],
    'win10-dell-xps' => [
        {
            NAME            => 'DELL JHXPY53',
            CAPACITY        => '57532',
            CHEMISTRY       => 'LiP',
            MANUFACTURER    => 'SMP',
            SERIAL          => '2677',
            REAL_CAPACITY   => '48807',
        }
    ],
);

my %testPowercfgMerged = (
    'windows-10-notebook' => {
        step1 => [
            {
                NAME            => '00HW023',
                CAPACITY        => '23540',
                VOLTAGE         => '11400',
                CHEMISTRY       => 'LiP',
                SERIAL          => '541',
                DATE            => '24/05/2018',
                MANUFACTURER    => 'SMP',
            },
            {
                NAME            => '01AV406',
                CAPACITY        => '26060',
                VOLTAGE         => '11460',
                CHEMISTRY       => 'LiP',
                SERIAL          => '3319',
                DATE            => '02/06/2018',
                MANUFACTURER    => 'SMP',
            }
        ],
        merged => [
            {
                NAME            => '00HW023',
                CAPACITY        => '23540',
                REAL_CAPACITY   => '19450',
                VOLTAGE         => '11400',
                CHEMISTRY       => 'LiP',
                SERIAL          => '541',
                DATE            => '24/05/2018',
                MANUFACTURER    => 'SMP',
            },
            {
                NAME            => '01AV406',
                CAPACITY        => '26060',
                REAL_CAPACITY   => '17860',
                VOLTAGE         => '11460',
                CHEMISTRY       => 'LiP',
                SERIAL          => '3319',
                DATE            => '02/06/2018',
                MANUFACTURER    => 'SMP',
            }
        ],
    },
    'win10-dell-xps' => {
        step1 => [
            {
                NAME            => 'DELL JHXPY53',
                CAPACITY        => '57530',
                VOLTAGE         => '7600',
                CHEMISTRY       => 'LiP',
                SERIAL          => '2677',
                DATE            => '15/09/2017',
                MANUFACTURER    => 'SMP',
            }
        ],
        merged => [
            {
                NAME            => 'DELL JHXPY53',
                CAPACITY        => '57532',
                VOLTAGE         => '7600',
                CHEMISTRY       => 'LiP',
                MANUFACTURER    => 'SMP',
                SERIAL          => '2677',
                DATE            => '15/09/2017',
                REAL_CAPACITY   => '48807',
            }
        ],
    },);

plan tests =>
    scalar (keys %testPowercfgInfos) +
    2 * scalar (keys %testPowercfgMerged) +
    1;

foreach my $test (keys %testPowercfgInfos) {
    my @batteries = GLPI::Agent::Task::Inventory::Win32::Batteries::_getBatteriesFromPowercfg(
        file => 'resources/win32/powercfg/' . $test . '.xml'
    );
    cmp_deeply(
        \@batteries,
        $testPowercfgInfos{$test},
        "$test: _getBatteriesFromPowercfg()"
    );
}

foreach my $test (keys %testPowercfgMerged) {

    my $list = Inventory::Batteries->new();

    # Prepare batteries list like it should be after dmidecode passed
    map { $list->add($_) }
        GLPI::Agent::Task::Inventory::Generic::Dmidecode::Battery::_getBatteries(
            file => $testPowercfgMerged{$test}->{dmidecode} // 'resources/generic/dmidecode/batteries/' . $test
        );

    cmp_deeply(
        [ sort { $a->{NAME} cmp $b->{NAME} } $list->list() ],
        $testPowercfgMerged{$test}->{step1},
        "test $test: merge step 1"
    );

    $list->merge(GLPI::Agent::Task::Inventory::Win32::Batteries::_getBatteriesFromPowercfg(
        file => 'resources/win32/powercfg/' . $test . '.xml'
    ));

    cmp_deeply(
        [ sort { $a->{NAME} cmp $b->{NAME} } $list->list() ],
        $testPowercfgMerged{$test}->{merged},
        "test $test: merged"
    );
}
