#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::Storages::Adaptec;

my %tests = (
    linux2 => {
        controller => 'scsi0',
        name       => 'foo',
        disks      => [
            {
                NAME         => 'foo',
                MODEL        => 'HUS151436VL3800',
                MANUFACTURER => 'Hitachi',
                FIRMWARE     => 'S3C0',
                device       => '/dev/sg1'
            },
            {
                NAME         => 'foo',
                MODEL        => 'HUS151436VL3800',
                MANUFACTURER => 'Hitachi',
                FIRMWARE     => 'S3C0',
                device       => '/dev/sg2'
            }
        ]
    },
    linux4 => {
        controller => 'scsi0',
        name       => 'foo',
        disks      => [
            {
                NAME         => 'foo',
                FIRMWARE     => 'V1.0',
                MANUFACTURER => 'Drive 1',
                MODEL        => 'Drive 1',
                device       => '/dev/sg0'
            },
            {
                NAME         => 'foo',
                FIRMWARE     => 'V1.0',
                MANUFACTURER => 'Drive 2',
                MODEL        => 'Drive 2',
                device       => '/dev/sg1'
            },
            {
                NAME         => 'foo',
                FIRMWARE     => 'BA23',
                MANUFACTURER => 'Seagate',
                MODEL        => 'ST3300655SS',
                device       => '/dev/sg2'
                },
                {
                NAME         => 'foo',
                FIRMWARE     => 'BA23',
                MANUFACTURER => 'Seagate',
                MODEL        => 'ST3300655SS',
                device       => '/dev/sg3'
            },
            {
                NAME         => 'foo',
                FIRMWARE     => 'BA23',
                MANUFACTURER => 'Seagate',
                MODEL        => 'ST3300655SS',
                device       => '/dev/sg4'
            },
            {
                NAME         => 'foo',
                FIRMWARE     => 'BA23',
                MANUFACTURER => 'Seagate',
                MODEL        => 'ST3300655SS',
                device       => '/dev/sg5'
            },
            {
                NAME         => 'foo',
                FIRMWARE     => 'BA23',
                MANUFACTURER => 'Seagate',
                MODEL        => 'ST3300655SS',
                device       => '/dev/sg6'
            },
            {
                NAME         => 'foo',
                FIRMWARE     => 'BA23',
                MANUFACTURER => 'Seagate',
                MODEL        => 'ST3300655SS',
                device       => '/dev/sg7'
            },
            {
                NAME         => 'foo',
                FIRMWARE     => '1.06',
                MANUFACTURER => 'VSC7160',
                MODEL        => 'VSC7160',
                device       => '/dev/sg8'
            }
        ]
    }
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/linux/proc/scsi/$test";
    my @disks = GLPI::Agent::Task::Inventory::Linux::Storages::Adaptec::_getDisksFromProc(
        file       => $file,
        controller => $tests{$test}->{controller},
        name       => $tests{$test}->{name},
    );
    cmp_deeply(\@disks, $tests{$test}->{disks}, "$test: parsing");
    delete $_->{device} foreach @disks;
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_) foreach @disks;
    } "$test: registering";
}
