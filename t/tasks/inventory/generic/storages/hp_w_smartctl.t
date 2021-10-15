#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Generic::Storages::HpWithSmartctl;

my %tests = (
    '1-ctrl-all-show-config' => {
        1 => {
            serial       => 'PACCRID10331H80',
            drives_total => '0'
        },
        0 => {
            serial       => '50014380095E2C50',
            drives_total => '8'
        }
    }
);

plan tests => (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file  = "resources/generic/hpacucli/$test";
    my $result = GLPI::Agent::Task::Inventory::Generic::Storages::HpWithSmartctl::_getData(file => $file);

    cmp_deeply(
        $result,
        $tests{$test},
        "$test: 'ctrl all show config' parsing"
    );
}
