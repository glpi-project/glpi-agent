#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Tools::Solaris;
use GLPI::Agent::Task::Inventory::Solaris::Hardware;

my %virtinfo_tests = (
    'solaris' => '915fbcf6-2b64-48ba-9b7b-05df341428be',
);

plan tests => (scalar keys %virtinfo_tests) + 1;

foreach my $test (keys %virtinfo_tests) {
    my $file   = "resources/solaris/virtinfo/$test";
    my $result = GLPI::Agent::Task::Inventory::Solaris::Hardware::_getUUIDGlobal(file => $file);
    is($result, $virtinfo_tests{$test}, "virtinfo parsing: $test");
}
