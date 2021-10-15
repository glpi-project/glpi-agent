#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::HPUX::Uptime;

my %tests = (
    sample1 => '10625700'
);

plan tests => (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file1 = "resources/hpux/uptime/$test";
    my $date = GLPI::Agent::Task::Inventory::HPUX::Uptime::_getUptime(file => $file1);
    is($date, $tests{$test}, "$test uptime parsing");
}
