#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::Storages::Megaraid;

my %tests = (
    sample => [
        {
            NAME         => 'a0e32s0',
            DISKSIZE     => '571392',
            DESCRIPTION  => 'SAS',
            MODEL        => 'ST3600057SS',
            MANUFACTURER => 'SEAGATE',
            TYPE         => 'disk'
        },
        {
            NAME         => 'a0e32s1',
            DISKSIZE     => '571392',
            DESCRIPTION  => 'SAS',
            MODEL        => 'ST3600057SS',
            MANUFACTURER => 'SEAGATE',
            TYPE         => 'disk'
        },
        {
            NAME         => 'a0e32s2',
            DISKSIZE     => '571392',
            DESCRIPTION  => 'SAS',
            MODEL        => 'ST3600057SS',
            MANUFACTURER => 'SEAGATE',
            TYPE         => 'disk'
        },
        {
            NAME         => 'a0e32s3',
            DISKSIZE     => '571392',
            DESCRIPTION  => 'SAS',
            MODEL        => 'ST3600057SS',
            MANUFACTURER => 'SEAGATE',
            TYPE         => 'disk'
        },
        {
            NAME         => 'a0e32s4',
            DISKSIZE     => '571392',
            DESCRIPTION  => 'SAS',
            MODEL        => 'ST3600057SS',
            MANUFACTURER => 'SEAGATE',
            TYPE         => 'disk'
        },
        {
            NAME         => 'a0e32s5',
            DISKSIZE     => '571392',
            DESCRIPTION  => 'SAS',
            MODEL        => 'ST3600057SS',
            MANUFACTURER => 'SEAGATE',
            TYPE         => 'disk'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/linux/megasasctl/$test";
    my @disks = GLPI::Agent::Task::Inventory::Linux::Storages::Megaraid::_parseMegasasctl(
        file       => $file
    );
    cmp_deeply(\@disks, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_) foreach @disks;
    } "$test: registering";
}
