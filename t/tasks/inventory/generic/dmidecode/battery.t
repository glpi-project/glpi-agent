#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::Dmidecode::Battery;

my %tests = (
    'freebsd-6.2' => undef,
    'freebsd-8.1' => [
        {
            NAME         => 'EV06047',
            SERIAL       => '25062',
            MANUFACTURER => 'LGC-LGC',
            CHEMISTRY    => 'Lithium Ion',
            VOLTAGE      => 10800,
            CAPACITY     => 4400,
            DATE         => '15/01/2010'
        }
    ],
    'linux-2.6' => [
        {
            NAME         => 'DELL C129563',
            MANUFACTURER => 'Samsung',
            SERIAL       => '7734',
            CHEMISTRY    => 'LION',
            VOLTAGE      => 11100,
            CAPACITY     => 48000,
            DATE         => '11/03/2006'
        }
    ],
    'macos-battery' => undef,
    'openbsd-3.7' => undef,
    'openbsd-3.8' => undef,
    'rhel-2.1' => undef,
    'rhel-3.4' => undef,
    'rhel-4.3' => undef,
    'rhel-4.6' => undef,
    'windows' => [
        {
            NAME         => 'L9088A',
            SERIAL       => '2000417915',
            DATE         => '19/09/2002',
            MANUFACTURER => 'Toshiba',
            CHEMISTRY    => 'Lithium Ion',
            VOLTAGE      => 10800,
        }
    ],
    'windows-hyperV' => undef,
    'windows-10-notebook' => [
        {
            NAME         => '00HW023',
            SERIAL       => '541',
            DATE         => '24/05/2018',
            MANUFACTURER => 'SMP',
            CHEMISTRY    => 'LiP',
            VOLTAGE      => 11400,
            CAPACITY     => 23540,
        },
        {
            NAME         => '01AV406',
            SERIAL       => '3319',
            DATE         => '02/06/2018',
            MANUFACTURER => 'SMP',
            CHEMISTRY    => 'LiP',
            VOLTAGE      => 11460,
            CAPACITY     => 26060,
        }
    ],
);

plan tests =>
    (scalar keys %tests)               +
    (scalar grep { $_ } values %tests) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/generic/dmidecode/$test";
    $file = "resources/generic/dmidecode/batteries/$test" unless -e $file;
    my @batteries = GLPI::Agent::Task::Inventory::Generic::Dmidecode::Battery::_getBatteries(file => $file);
    cmp_deeply(\@batteries, $tests{$test} || [], "$test: parsing");
    next unless @batteries;
    lives_ok {
        $inventory->addEntry(section => 'BATTERIES', entry => $batteries[0]);
    } "$test: registering";
}
