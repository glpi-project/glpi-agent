#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use FusionInventory::Test::Inventory;
use FusionInventory::Agent::Task::Inventory::Generic::Drives::ASM;

my %lsdg_tests = (
    'grid-1' => [
        [
            {
                'FREE'  => 11270549,
                'NAME'  => 'DATA',
                'STATE' => 'MOUNTED',
                'TOTAL' => 15033685,
                'TYPE'  => 'HIGH'
            },
            {
                'FREE'  => 286386,
                'NAME'  => 'FLASH',
                'STATE' => 'MOUNTED',
                'TOTAL' => 572328,
                'TYPE'  => 'NORMAL'
            },
            {
                'FREE'  => 14889260,
                'NAME'  => 'RECO',
                'STATE' => 'MOUNTED',
                'TOTAL' => 19971709,
                'TYPE'  => 'HIGH'
            },
            {
                'FREE'  => 52562,
                'NAME'  => 'REDO',
                'STATE' => 'MOUNTED',
                'TOTAL' => 127186,
                'TYPE'  => 'HIGH'
            }
        ]
    ],
    'oracle-1' => [
        [
            {
                'FREE'  => 562844,
                'NAME'  => 'DATA',
                'STATE' => 'MOUNTED',
                'TOTAL' => 2047997,
                'TYPE'  => 'EXTERN'
            },
            {
                'FREE'  => 16535,
                'NAME'  => 'OCRVOTE',
                'STATE' => 'MOUNTED',
                'TOTAL' => 52223,
                'TYPE'  => 'EXTERN'
            }
        ]
    ],
);

plan tests => (scalar keys %lsdg_tests) + 1;

my $inventory = FusionInventory::Test::Inventory->new();

foreach my $test (keys %lsdg_tests) {
    my $file = "resources/generic/asmcmd/$test";
    my @groups = FusionInventory::Agent::Task::Inventory::Generic::Drives::ASM::_getDisksGroups(file => $file);
    cmp_deeply(\@groups, $lsdg_tests{$test}, "$test: lsdg parsing");
}
