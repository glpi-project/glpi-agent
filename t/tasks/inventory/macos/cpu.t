#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::MacOS::CPU;

my %tests = (
    '10.6-macmini' => [
        {
            CORE         => '2',
            MANUFACTURER => 'Intel',
            NAME         => 'Intel(R) Core(TM)2 Duo CPU P7550 @ 2.26GHz',
            THREAD       => 2,
            FAMILYNUMBER => '6',
            MODEL        => '23',
            STEPPING     => '10',
            SPEED        => '2260'
        },
    ],
    '11.0-apple-M1' => [
        {
            CORE         => '8',
            MANUFACTURER => 'Apple',
            NAME         => 'Apple M1',
            THREAD       => 8,
        },
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $sysctl = "resources/macos/sysctl/$test";
    my $file = "resources/macos/system_profiler/$test";
    my @cpus = GLPI::Agent::Task::Inventory::MacOS::CPU::_getCpus(file => $file,sysctl => $sysctl);
    cmp_deeply(\@cpus, $tests{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } "$test: registering";
}
