#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::HPUX::CPU;

my %machinfo_tests = (
    'hpux_11.31_3xia64' => {
        CPUcount     => '3',
        SPEED        => '1600',
        NAME         => 'Itanium',
        MANUFACTURER => 'Intel',
    },
    'hpux_11.23.ia64' => {
        CPUcount     => '2',
        NAME         => 'Itanium',
        MANUFACTURER => 'Intel',
        SPEED       => '1600'
    },
    'hpux_11.31-1' => {
        NAME         => 'Itanium',
        CPUcount     => '3',
        MANUFACTURER => 'Intel',
        SPEED        => '1600'
    },
    'hpux_11.31-2' => {
        NAME         => 'Itanium',
        CPUcount     => '2',
        CORE         => 4,
        MANUFACTURER => 'Intel',
        SPEED        => '1730'
    },
    'hpux_11.31-3' => {
        NAME         => 'Itanium',
        CPUcount     => '2',
        MANUFACTURER => 'Intel',
        SPEED        => '1600'
    },
    'hpux_11.31-superdome' => {
        NAME         => 'Itanium',
        CPUcount     => 1,
        MANUFACTURER => 'Intel',
        SPEED        => '1600',
        CORE         => '2'
    }
);

my %cprop_tests = (
    hpux4 => [
        {
            ID           => 'ff-ff-ff-3-ff-0-ff-11',
            NAME         => 'Itanium',
            MANUFACTURER => 'Intel',
            SPEED        => '1729',
            CORE         => 4
        },
        {
            ID           => 'ff-ff-ff-4-ff-0-ff-11',
            NAME         => 'Itanium',
            MANUFACTURER => 'Intel',
            SPEED        => '1729',
            CORE         => 4
        }
    ]
);

plan tests =>
    (2 * scalar keys %machinfo_tests) +
    (2 * scalar keys %cprop_tests)    +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %machinfo_tests) {
    my $file = "resources/hpux/machinfo/$test";
    my $cpus = GLPI::Agent::Task::Inventory::HPUX::CPU::_parseMachinInfo(file => $file);
    cmp_deeply($cpus, $machinfo_tests{$test}, "machinfo parsing: $test");
    delete $cpus->{CPUcount};
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $cpus);
    } "$test: registering";
}

foreach my $test (keys %cprop_tests) {
    my $file = "resources/hpux/cprop/$test-cpu";
    my @cpus = GLPI::Agent::Task::Inventory::HPUX::CPU::_parseCprop(file => $file);
    cmp_deeply(\@cpus, $cprop_tests{$test}, "cprop parsing: $test");
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } "$test: registering";
}
