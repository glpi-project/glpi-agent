#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Solaris::OS;

my %installdate_tests = (
    'oi-2021.10'    => "2021-10-31 20:36:45",
);

plan tests => (scalar keys %installdate_tests) + 1;

foreach my $test (keys %installdate_tests) {
    my $file = "resources/solaris/pkg-info/installdate-$test";
    my $installdate = GLPI::Agent::Task::Inventory::Solaris::OS::_getInstallDate(file => $file);
    is($installdate, $installdate_tests{$test}, "$test: installdate");
}
