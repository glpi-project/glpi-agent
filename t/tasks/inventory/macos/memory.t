#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::MacOS::Memory;

my %memories_tests = (
    '10.4-powerpc' => [
        {
            NUMSLOTS     => '0',
            SERIALNUMBER => undef,
            SPEED        => undef,
            TYPE         => 'DDR2 SDRAM',
            CAPACITY     => 1024,
            CAPTION      => 'Status: OK'
        },
        {
            NUMSLOTS     => '1',
            SERIALNUMBER => undef,
            SPEED        => undef,
            TYPE         => 'DDR2 SDRAM',
            CAPACITY     => 1024,
            CAPTION      => 'Status: OK'
        },
        {
            NUMSLOTS     => '2',
            SERIALNUMBER => undef,
            SPEED        => undef,
            TYPE         => 'Empty',
            CAPACITY     => undef,
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => '3',
            SERIALNUMBER => undef,
            SPEED        => undef,
            TYPE         => 'Empty',
            CAPACITY     => undef,
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => '4',
            SERIALNUMBER => undef,
            SPEED        => undef,
            TYPE         => 'Empty',
            CAPACITY     => undef,
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => '5',
            SERIALNUMBER => undef,
            SPEED        => undef,
            TYPE         => 'Empty',
            CAPACITY     => undef,
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => '6',
            SERIALNUMBER => undef,
            SPEED        => undef,
            TYPE         => 'Empty',
            CAPACITY     => undef,
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => '7',
            SERIALNUMBER => undef,
            SPEED        => undef,
            TYPE         => 'Empty',
            CAPACITY     => undef,
            CAPTION      => 'Status: Empty'
        }
    ],
    '10.5-powerpc' => [
        {
            NUMSLOTS     => 0,
            SERIALNUMBER => 'Unknown',
            DESCRIPTION  => 'Unknown',
            SPEED        => undef,
            CAPACITY     => undef,
            TYPE         => 'DDR2 SDRAM',
            CAPACITY     => '1024',
            CAPTION      => 'Status: OK'
        },
        {
            NUMSLOTS     => 1,
            SERIALNUMBER => 'Unknown',
            DESCRIPTION  => 'Unknown',
            SPEED        => undef,
            CAPACITY     => undef,
            TYPE         => 'DDR2 SDRAM',
            CAPACITY     => '1024',
            CAPTION      => 'Status: OK'
        },
        {
            NUMSLOTS     => 2,
            SERIALNUMBER => 'Empty',
            DESCRIPTION  => 'Empty',
            SPEED        => undef,
            CAPACITY     => undef,
            TYPE         => 'Empty',
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => 3,
            SERIALNUMBER => 'Empty',
            DESCRIPTION  => 'Empty',
            SPEED        => undef,
            CAPACITY     => undef,
            TYPE         => 'Empty',
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => 4,
            SERIALNUMBER => 'Empty',
            DESCRIPTION  => 'Empty',
            SPEED        => undef,
            CAPACITY     => undef,
            TYPE         => 'Empty',
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => 5,
            SERIALNUMBER => 'Empty',
            DESCRIPTION  => 'Empty',
            SPEED        => undef,
            CAPACITY     => undef,
            TYPE         => 'Empty',
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => 6,
            SERIALNUMBER => 'Empty',
            DESCRIPTION  => 'Empty',
            SPEED        => undef,
            CAPACITY     => undef,
            TYPE         => 'Empty',
            CAPTION      => 'Status: Empty'
        },
        {
            NUMSLOTS     => 7,
            SERIALNUMBER => 'Empty',
            DESCRIPTION  => 'Empty',
            SPEED        => undef,
            CAPACITY     => undef,
            TYPE         => 'Empty',
            CAPTION      => 'Status: Empty'
        }
    ],
    '10.6-macmini' => [
        {
            NUMSLOTS     => 0,
            SERIALNUMBER => '0x00000000',
            SPEED        => '1067',
            TYPE         => 'DDR3',
            CAPACITY     => '2048',
            CAPTION      => 'Status: OK'
        },
       {
            NUMSLOTS     => 0,
            SERIALNUMBER => '0x00000000',
            SPEED        => '1067',
            TYPE         => 'DDR3',
            CAPACITY     => '2048',
            CAPTION      => 'Status: OK'
        },
    ],
    '10.6-intel' => [
        {
            NUMSLOTS     => 0,
            SERIALNUMBER => '0xD5289015',
            DESCRIPTION  => 'X38HTF12864HDY-667E1',
            SPEED        => '667',
            TYPE         => 'DDR2 SDRAM',
            CAPACITY     => '1024',
            CAPTION      => 'Status: OK'
        },
        {
            NUMSLOTS     => 1,
            SERIALNUMBER => '0x00000000',
            DESCRIPTION  => '1024636750S',
            SPEED        => '667',
            TYPE         => 'DDR2 SDRAM',
            CAPACITY     => '1024',
            CAPTION      => 'Status: OK'
        }
    ],
    '10.6-intel' => [
        {
            NUMSLOTS     => '0',
            SERIALNUMBER => '0xD5289015',
            DESCRIPTION  => '8HTF12864HDY-667E1',
            SPEED        => '667',
            TYPE         => 'DDR2 SDRAM',
            CAPACITY     => 1024,
            CAPTION      => 'Status: OK'
        },
        {
            NUMSLOTS     => '1',
            SERIALNUMBER => '0x00000000',
            DESCRIPTION  => '1024636750S',
            SPEED        => '667',
            TYPE         => 'DDR2 SDRAM',
            CAPACITY     => 1024,
            CAPTION      => 'Status: OK'
        }
    ],
    '11.0-apple-M1' => [
        {
            NUMSLOTS     => 0,
            TYPE         => 'LPDDR4',
            CAPACITY     => '16384',
            DESCRIPTION  => 'Integrated memory',
        },
    ],
);

my %memory_tests = (
    '10.4-powerpc' => 2048,
    '10.5-powerpc' => 2048,
    '10.6-macmini' => 4096,
    '10.6-intel'   => 2048,
    '11.0-apple-M1' => 16384,
);

plan tests =>
    (2 * scalar keys %memories_tests) +
    (scalar keys %memory_tests)       +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %memories_tests) {
    my $file = "resources/macos/system_profiler/$test";
    my @memories = GLPI::Agent::Task::Inventory::MacOS::Memory::_getMemories(file => $file);
    cmp_deeply(\@memories, $memories_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'MEMORIES', entry => $_)
            foreach @memories;
    } "$test: registering";
}

foreach my $test (keys %memory_tests) {
    my $file = "resources/macos/system_profiler/$test";
    my $memory = GLPI::Agent::Task::Inventory::MacOS::Memory::_getMemory(file => $file);
    is($memory, $memory_tests{$test}, $test);
};
