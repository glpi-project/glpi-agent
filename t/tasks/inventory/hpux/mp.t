#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::HPUX::MP;

my %tests = (
    hpux2 => '10.0.14.60'
);

plan tests => (2 * scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file1 = "resources/hpux/getMPInfo.cgi/$test";
    my $address1 = GLPI::Agent::Task::Inventory::HPUX::MP::_parseGetMPInfo(file => $file1);
    is($address1, $tests{$test}, "$test getGMPInfo parsing");

    my $file2 = "resources/hpux/CIMUtil/$test";
    my $address2 = GLPI::Agent::Task::Inventory::HPUX::MP::_parseCIMUtil(file => $file2);
    is($address2, $tests{$test}, "$test CIMUtil parsing");
}
