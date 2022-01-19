#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Solaris::Memory;

my %tests = (
    sample1 => [ _gen(4,  'NUMSLOTS', { TYPE => "DIMM", CAPACITY => '1024'  }) ],
    sample2 => [ _gen(64, 'NUMSLOTS', { TYPE => "DIMM", CAPACITY => '512'   }) ],
    sample3 => [ _gen(16, 'NUMSLOTS', { TYPE => 'DDR2', DESCRIPTION  => "DIMM" }) ],
    sample4 => [ _gen(8,  'NUMSLOTS', { TYPE => 'DDR',  DESCRIPTION  => "DIMM" }) ],
    sample5 => [ _gen(2,  'NUMSLOTS', { TYPE => 'DRAM', DESCRIPTION  => "RAM"  }) ],
    sample6 => [ _gen(8,  'NUMSLOTS', { TYPE => "DIMM", CAPACITY => '512'   }) ],
    sample7 => [ _gen(1,  'NUMSLOTS', { TYPE => "DIMM", CAPACITY => '2048'  }) ],
    sample8 => [ _gen(32, 'NUMSLOTS', { TYPE => "DIMM", CAPACITY => '2048'  }) ],
    oi151   => [ _gen(8,  'NUMSLOTS', { TYPE => "Unknown", DESCRIPTION  => "DIMM" }) ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/solaris/prtdiag/$test";
    my @memories =
      GLPI::Agent::Task::Inventory::Solaris::Memory::_getMemoriesPrtdiag(file => $file);
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

sub _gen {
    my ($count, $key, $base) = @_;

    my @objects;
    foreach my $i (1 .. $count) {
        my $object = _clone($base);
        $object->{$key} = $i - 1;
        push @objects, $object;
    }

    return @objects;
}

sub _clone {
    my ($base) = @_;

    my $object;
    foreach my $key (keys %$base) {
        $object->{$key} = $base->{$key};
    }

    return $object;
}
