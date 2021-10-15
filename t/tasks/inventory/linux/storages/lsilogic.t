#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::Storages::Lsilogic;

my %tests = (
    sample1 => {
        name       => 'foo',
        disks   => [
             {
                DISKSIZE     => '152576',
                NAME         => 'foo',
                FIRMWARE     => 'D',
                MANUFACTURER => 'Seagate',
                MODEL        => 'ST3160815AS',
                device       => '/dev/sg1',
            },
            {
                DISKSIZE     => '152576',
                NAME         => 'foo',
                FIRMWARE     => 'D',
                MANUFACTURER => 'Seagate',
                MODEL        => 'ST3160815AS',
                device       => '/dev/sg0',
          }
        ]
    },
    sample2 => {
        name       => 'foo',
        disks      => [
            {
                DISKSIZE     => '139264',
                NAME         => 'foo',
                FIRMWARE     => 'C610',
                MANUFACTURER => 'CBRCA146C3ETS0 N',
                MODEL        => 'CBRCA146C3ETS0 N',
                device       => '/dev/sg5',
            },
            {
                DISKSIZE     => '139264',
                NAME         => 'foo',
                FIRMWARE     => 'C610',
                MANUFACTURER => 'CBRCA146C3ETS0 N',
                MODEL        => 'CBRCA146C3ETS0 N',
                device       => '/dev/sg4',
            },
            {
                DISKSIZE     => '139264',
                NAME         => 'foo',
                FIRMWARE     => 'B53C',
                MANUFACTURER => 'Seagate',
                MODEL        => 'ST9146803SS',
                device       => '/dev/sg3',
            },
            {
                DISKSIZE     => '139264',
                NAME         => 'foo',
                FIRMWARE     => 'C610',
                MANUFACTURER => 'CBRCA146C3ETS0 N',
                MODEL        => 'CBRCA146C3ETS0 N',
                device       => '/dev/sg2',
            },
            {
                DISKSIZE     => '139264',
                NAME         => 'foo',
                FIRMWARE     => 'C610',
                MANUFACTURER => 'CBRCA146C3ETS0 N',
                MODEL        => 'CBRCA146C3ETS0 N',
                device       => '/dev/sg1',
            },
            {
                DISKSIZE     => '139264',
                NAME         => 'foo',
                FIRMWARE     => 'C610',
                MANUFACTURER => 'CBRCA146C3ETS0 N',
                MODEL        => 'CBRCA146C3ETS0 N',
                device       => '/dev/sg0',
            }
        ]
    }
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/linux/mpt-status/$test";
    my @disks = GLPI::Agent::Task::Inventory::Linux::Storages::Lsilogic::_getDiskFromMptStatus(
        file       => $file,
        name       => $tests{$test}->{name},
    );
    cmp_deeply(\@disks, $tests{$test}->{disks}, "$test: parsing");
    delete $_->{device} foreach @disks;
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_) foreach @disks;
    } "$test: registering";
}
