#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::HPUX::Storages;

my %tests = (
    'hpux1-tape' => [
        {
            NAME        => '/dev/rmt/0m',
            DESCRIPTION => 'scsi',
            MODEL       => 'C7438A',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/rmt/0mb',
            DESCRIPTION => 'scsi',
            MODEL       => 'C7438A',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/rmt/0mn',
            DESCRIPTION => 'scsi',
            MODEL       => 'C7438A',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/rmt/0mnb',
            DESCRIPTION => 'scsi',
            MODEL       => 'C7438A',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/rmt/7m',
            DESCRIPTION => 'scsi',
            MODEL       => 'Ultrium 4-SCSI',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/rmt/7mb',
            DESCRIPTION => 'scsi',
            MODEL       => 'Ultrium 4-SCSI',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/rmt/7mn',
            DESCRIPTION => 'scsi',
            MODEL       => 'Ultrium 4-SCSI',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/rmt/8m',
            DESCRIPTION => 'scsi',
            MODEL       => 'Ultrium 4-SCSI',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/rmt/8mb',
            DESCRIPTION => 'scsi',
            MODEL       => 'Ultrium 4-SCSI',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/rmt/8mn',
            DESCRIPTION => 'scsi',
            MODEL       => 'Ultrium 4-SCSI',
            MANUFACTURER => 'HP'
        }
    ],
    'hpux1-disk' => [
        {
            NAME        => '/dev/dsk/c0t0d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'DV-28E-N',
            MANUFACTURER => 'TEAC'
        },
        {
            NAME        => '/dev/dsk/c6t0d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'LOGICAL VOLUME',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c6t0d0s1',
            DESCRIPTION => 'scsi',
            MODEL       => 'LOGICAL VOLUME',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c6t0d1',
            DESCRIPTION => 'scsi',
            MODEL       => 'LOGICAL VOLUME',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c7t0d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008B26C',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c7t1d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008B26C',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c7t2d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF30084971',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c7t3d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008B26C',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c7t4d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008AFEC',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c7t5d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008B26C',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c7t8d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008B26C',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c8t0d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008B26C',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c8t1d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008B26C',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c8t2d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008B26C',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c8t3d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008AFEC',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c8t4d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF30084971',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c8t5d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008AFEC',
            MANUFACTURER => 'COMPAQ'
        },
        {
            NAME        => '/dev/dsk/c8t8d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'BF3008B26C',
            MANUFACTURER => 'COMPAQ'
        }
    ],
    'hpux2-disk' => [
        {
            NAME        => '/dev/dsk/c0t0d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'DV-28E-N',
            MANUFACTURER => 'TEAC'
        },
        {
            NAME        => '/dev/dsk/c5t0d1',
            DESCRIPTION => 'scsi',
            MODEL       => 'HSV200',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c5t1d2',
            DESCRIPTION => 'scsi',
            MODEL       => 'HSV200',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c7t0d1',
            DESCRIPTION => 'scsi',
            MODEL       => 'HSV200',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c7t1d2',
            DESCRIPTION => 'scsi',
            MODEL       => 'HSV200',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c9t0d1',
            DESCRIPTION => 'scsi',
            MODEL       => 'HSV200',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c9t1d2',
            DESCRIPTION => 'scsi',
            MODEL       => 'HSV200',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c11t0d1',
            DESCRIPTION => 'scsi',
            MODEL       => 'HSV200',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c11t1d2',
            DESCRIPTION => 'scsi',
            MODEL       => 'HSV200',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c4t0d0',
            DESCRIPTION => 'scsi',
            MODEL       => 'LOGICAL VOLUME',
            MANUFACTURER => 'HP'
        },
        {
            NAME        => '/dev/dsk/c4t0d0s1',
            DESCRIPTION => 'scsi',
            MODEL       => 'LOGICAL VOLUME',
            MANUFACTURER => 'HP'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/hpux/ioscan/$test";
    my @devices = GLPI::Agent::Task::Inventory::HPUX::Storages::_parseIoscan(file => $file);
    cmp_deeply(\@devices, $tests{$test}, "$test ioscan parsing");
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_)
            foreach @devices;
    } "$test: registering";
}
