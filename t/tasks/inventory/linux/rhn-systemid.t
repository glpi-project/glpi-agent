#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Linux::Hardware;

my %tests = (
    'ID-1232324425' => 'ID-123232425'
);
plan tests => (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/linux/rhn-systemid/$test";
    my $rhenSysteId = GLPI::Agent::Task::Inventory::Linux::Hardware::_getRHNSystemId($file);
    ok($rhenSysteId, $tests{$test});
}
