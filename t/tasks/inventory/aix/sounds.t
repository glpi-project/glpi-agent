#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::AIX::Sounds;

my %tests = (
    'aix-4.3.1' => [],
    'aix-4.3.2' => [],
    'aix-5.3a'  => [],
    'aix-5.3b'  => [],
    'aix-5.3c'  => [],
    'aix-6.1a'  => [],
    'aix-6.1b'  => [],
);

plan tests => (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/aix/lsdev/$test-adapter";
    my @sounds = GLPI::Agent::Task::Inventory::AIX::Sounds::_getSounds(file => $file);
    cmp_deeply(\@sounds, $tests{$test}, "sounds: $test");
}
