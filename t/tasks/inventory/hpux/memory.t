#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::HPUX::Memory;

my %cstm_tests = (
    'hpux' => []
);

my %cstm64_tests = (
    hpux1 => [
        {
            NUMSLOTS    => '0A',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 0A',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '0B',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 0B',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '1A',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 1A',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '1B',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 1B',
            CAPACITY    => '1024'
        },
    ],
    hpux => [
        {
            NUMSLOTS    => '0A',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 0A',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '0B',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 0B',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '0C',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 0C',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '0D',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 0D',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '1A',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 1A',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '1B',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 1B',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '1C',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 1C',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => '1D',
            DESCRIPTION => 'DIMM',
            TYPE        => 'DIMM',
            CAPTION     => 'DIMM 1D',
            CAPACITY    => '1024'
        },
    ],
);

my %cprop_tests = (
    hpux4 => [
        {
            SERIALNUMBER => 'f9d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'cad94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '2fd94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '6cd94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '72d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'aed94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'cbd94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '27d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'fed94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'fdd94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'd0d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '71d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'a7d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '26d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'e8d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '46da4044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'e3d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '2ed94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '2dd94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'a6d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '67d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'cfd94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => 'e7d94044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        },
        {
            SERIALNUMBER => '4cda4044271001',
            DESCRIPTION  => 'M393B5270CH0-CH9',
            TYPE         => 'DIMM',
            CAPACITY     => '4096'
        }
    ]
);

plan tests =>
    (2 * scalar keys %cstm_tests)   +
    (2 * scalar keys %cstm64_tests) +
    (2 * scalar keys %cprop_tests)  +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %cstm_tests) {
    my $file = "resources/hpux/cstm/$test-mem";
    my @memories = GLPI::Agent::Task::Inventory::HPUX::Memory::_parseCstm(file => $file);
    cmp_deeply(\@memories, $cstm_tests{$test}, "cstm parsing: $test");
    lives_ok {
        $inventory->addEntry(section => 'MEMORIES', entry => $_)
            foreach @memories;
    } "$test: registering";
}

foreach my $test (keys %cstm64_tests) {
    my $file = "resources/hpux/cstm/$test-MEMORY";
    my @memories = GLPI::Agent::Task::Inventory::HPUX::Memory::_parseCstm64(file => $file);
    cmp_deeply(\@memories, $cstm64_tests{$test}, "cstm 64 parsing: $test");
    lives_ok {
        $inventory->addEntry(section => 'MEMORIES', entry => $_)
            foreach @memories;
    } "$test: registering";
}

foreach my $test (keys %cprop_tests) {
    my $file = "resources/hpux/cprop/$test-memory";
    my @memories = GLPI::Agent::Task::Inventory::HPUX::Memory::_parseCprop(file => $file);
    cmp_deeply(\@memories, $cprop_tests{$test}, "cprop parsing: $test");
    lives_ok {
        $inventory->addEntry(section => 'MEMORIES', entry => $_)
            foreach @memories;
    } "$test: registering";
}
