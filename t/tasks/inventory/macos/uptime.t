#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::MacOS::Uptime;
use GLPI::Agent::Tools::MacOS;

my %tests = (
    '1325070226' => '1325070226',
    'sec = 1325070226' => '1325070226',
    '{ sec = 1476344326, usec = 0 } Thu Oct 13 09:38:46 2016' => '1476344326'
);

plan tests => (scalar keys %tests) * 2 + 1;

foreach my $test (keys %tests) {
    my $r = GLPI::Agent::Tools::MacOS::getBootTime(string => $test);
    ok($r);
    ok($r eq $tests{$test}, $r . ' eq ? ' . $tests{$test});
}
