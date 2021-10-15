#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More;
use UNIVERSAL::require;

use GLPI::Agent::Inventory;
use GLPI::Test::Utils;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

Test::NoWarnings->use();

GLPI::Agent::Task::Inventory::Win32::Memory->require();

my %tests = (
    '7' => [
        {
            NUMSLOTS     => 0,
            FORMFACTOR   => 'DIMM',
            SERIALNUMBER => '0000000',
            TYPE         => 'Unknown',
            SPEED        => '1600',
            CAPTION      => "Mémoire physique",
            REMOVABLE    => 0,
            DESCRIPTION  => "Mémoire physique",
            CAPACITY     => '2048'
        },
        {
            NUMSLOTS     => 1,
            FORMFACTOR   => 'DIMM',
            SERIALNUMBER => '0000000',
            TYPE         => 'Unknown',
            SPEED        => '1600',
            CAPTION      => "Mémoire physique",
            REMOVABLE    => 0,
            DESCRIPTION  => "Mémoire physique",
            CAPACITY     => '2048'
        }
    ],
    'xp' => [
        {
            NUMSLOTS     => 0,
            FORMFACTOR   => 'DIMM',
            SERIALNUMBER => undef,
            TYPE         => 'Unknown',
            SPEED        => '800',
            CAPTION      => 'Physical Memory',
            REMOVABLE    => 0,
            DESCRIPTION  => 'Physical Memory',
            CAPACITY     => '2048'
        },
        {
            NUMSLOTS     => 1,
            FORMFACTOR   => 'DIMM',
            SERIALNUMBER => undef,
            TYPE         => 'Unknown',
            SPEED        => '800',
            CAPTION      => 'Physical Memory',
            REMOVABLE    => 0,
            DESCRIPTION  => 'Physical Memory',
            MEMORYCORRECTION => 'None',
            CAPACITY     => '2048'
        }
      ],
    '2003' => [
        {
            NUMSLOTS     => 0,
            FORMFACTOR   => 'DIMM',
            SERIALNUMBER => undef,
            TYPE         => 'Unknown',
            SPEED        => '266',
            CAPTION      => 'Physical Memory',
            REMOVABLE    => 0,
            DESCRIPTION  => 'Physical Memory',
            CAPACITY     => '1024'
        },
        {
            NUMSLOTS     => 1,
            FORMFACTOR   => 'DIMM',
            SERIALNUMBER => undef,
            TYPE         => 'Unknown',
            SPEED        => '266',
            CAPTION      => 'Physical Memory',
            REMOVABLE    => 0,
            DESCRIPTION  => 'Physical Memory',
            CAPACITY     => '1024'
        }
      ],
    '2003SP2' => [
        {
            NUMSLOTS     => 0,
            FORMFACTOR   => 'DIMM',
            SERIALNUMBER => undef,
            TYPE         => 'DRAM',
            SPEED        => undef,
            CAPTION      => 'Physical Memory',
            REMOVABLE    => 0,
            DESCRIPTION  => 'Physical Memory',
            CAPACITY     => '1024'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new();

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::Memory'
);

foreach my $test (keys %tests) {
    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    my @memories = GLPI::Agent::Task::Inventory::Win32::Memory::_getMemories();
    cmp_deeply(
        \@memories,
        $tests{$test},
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'MEMORIES', entry => $_)
            foreach @memories;
    } "$test: registering";
}
