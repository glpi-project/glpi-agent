#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::AIX::Storages;

my %lsdev_tests = (
    'aix-4.3.1-disk-scsi' => [
        {
            NAME        => 'hdisk0',
            DESCRIPTION => '16 Bit SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk1',
            DESCRIPTION => '16 Bit SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk2',
            DESCRIPTION => '16 Bit SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk3',
            DESCRIPTION => '16 Bit SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk4',
            DESCRIPTION => 'Other SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk5',
            DESCRIPTION => 'Other SCSI Disk Drive',
        }
    ],
    'aix-4.3.2-disk-scsi' => [
        {
            NAME        => 'hdisk0',
            DESCRIPTION => '16 Bit SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk1',
            DESCRIPTION => '16 Bit SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk2',
            DESCRIPTION => '16 Bit SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk3',
            DESCRIPTION => '16 Bit SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk4',
            DESCRIPTION => 'Other SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk5',
            DESCRIPTION => 'Other SCSI Disk Drive',
        }
    ],
    'aix-5.3a-disk-scsi' => [
        {
            NAME        => 'hdisk0',
            DESCRIPTION => '16 Bit LVD SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk1',
            DESCRIPTION => '16 Bit LVD SCSI Disk Drive',
        }
    ],
    'aix-5.3b-disk-scsi' => [
        {
            NAME        => 'hdisk0',
            DESCRIPTION => 'SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk1',
            DESCRIPTION => 'SCSI Disk Drive',
        }
    ],
    'aix-5.3c-disk-vscsi' => [
        {
            NAME        => 'hdisk0',
            DESCRIPTION => 'Virtual SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk1',
            DESCRIPTION => 'Virtual SCSI Disk Drive',
        }
    ],
    'aix-6.1a-disk-fcp' => [
        {
            NAME        => 'hdisk2',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk3',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk4',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk5',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk6',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk7',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk8',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk9',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk10',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk11',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk12',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk13',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk14',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk15',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk16',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk17',
            DESCRIPTION => 'Other FC SCSI Disk Drive',
        }
    ],
    'aix-6.1a-disk-vscsi' => [
        {
            NAME        => 'hdisk0',
            DESCRIPTION => 'Virtual SCSI Disk Drive',
        },
        {
            NAME        => 'hdisk1',
            DESCRIPTION => 'Virtual SCSI Disk Drive',
        }
    ],
    'aix-6.1b-disk-sas' => [
        {
            NAME        => 'hdisk0',
            DESCRIPTION => 'SAS RAID 10 Disk Array',
        },
        {
            NAME        => 'hdisk1',
            DESCRIPTION => 'MPIO DS3200 SAS Disk',
        },
        {
            NAME        => 'hdisk2',
            DESCRIPTION => 'MPIO DS3200 SAS Disk',
        },
        {
            NAME        => 'hdisk4',
            DESCRIPTION => 'MPIO DS3200 SAS Disk',
        },
        {
            NAME        => 'hdisk5',
            DESCRIPTION => 'MPIO DS3200 SAS Disk',
        },
        {
            NAME        => 'hdisk6',
            DESCRIPTION => 'MPIO DS3200 SAS Disk',
        },
        {
            NAME        => 'hdisk7',
            DESCRIPTION => 'MPIO DS3200 SAS Disk',
        }
    ],
);

my %disk_tests = (
    'aix-6.1a' => {
        type  => 'fcp',
        disks => [
            {
                NAME        => 'hdisk2',
                DESCRIPTION => 'Other FC SCSI Disk Drive',
                TYPE        => 'disk',
            },
            {
                NAME         => 'hdisk3',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk4',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk5',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk6',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk7',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk8',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk9',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk10',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk11',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk12',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk13',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk14',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk15',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk16',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            },
            {
                NAME         => 'hdisk17',
                DESCRIPTION  => 'Other FC SCSI Disk Drive',
                TYPE         => 'disk',
                MODEL        => 'DF600F',
                MANUFACTURER => 'HITACHI',
            }
        ]
    },
    'aix-6.1b' => {
        type  => 'sas',
        disks => [
            {
                NAME         => 'hdisk0',
                DESCRIPTION  => 'SAS RAID 10 Disk Array',
                TYPE         => 'disk'
            },
            {
                NAME         => 'hdisk1',
                DESCRIPTION  => 'MPIO DS3200 SAS Disk',
                TYPE         => 'disk',
                MODEL        => '1726-2xx  FAStT',
                MANUFACTURER => 'IBM',
            },
            {
                NAME         => 'hdisk2',
                DESCRIPTION  => 'MPIO DS3200 SAS Disk',
                TYPE         => 'disk',
                MODEL        => '1726-2xx  FAStT',
                MANUFACTURER => 'IBM',
            },
            {
                NAME         => 'hdisk4',
                DESCRIPTION  => 'MPIO DS3200 SAS Disk',
                TYPE         => 'disk',
                MODEL        => '1726-2xx  FAStT',
                MANUFACTURER => 'IBM',
            },
            {
                NAME         => 'hdisk5',
                DESCRIPTION  => 'MPIO DS3200 SAS Disk',
                TYPE         => 'disk',
                MODEL        => '1726-2xx  FAStT',
                MANUFACTURER => 'IBM',
            },
            {
                NAME         => 'hdisk6',
                DESCRIPTION  => 'MPIO DS3200 SAS Disk',
                TYPE         => 'disk',
                MODEL        => '1726-2xx  FAStT',
                MANUFACTURER => 'IBM',
            },
            {
                NAME         => 'hdisk7',
                DESCRIPTION  => 'MPIO DS3200 SAS Disk',
                TYPE         => 'disk',
                MODEL        => '1726-2xx  FAStT',
                MANUFACTURER => 'IBM',
            }
        ],
    }
);

my %lspv_tests = (
    'aix-6.1-hdisk0' => 34752,
    'aix-6.1-hdisk1' => undef,
    'aix-6.1-hdisk2' => 102272,
    'aix-6.1-hdisk3' => 30592,
);

plan tests =>
    (2 * scalar keys %lsdev_tests) +
    (2 * scalar keys %disk_tests)  +
    (scalar keys %lspv_tests)      +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %lsdev_tests) {
    my $file = "resources/aix/lsdev/$test";
    my @devices = GLPI::Agent::Task::Inventory::AIX::Storages::_parseLsdev(file => $file, pattern => qr/^(.+):(.+)/);
    cmp_deeply(\@devices, $lsdev_tests{$test}, "lsdev parsing: $test");
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_)
            foreach @devices ;
    } "$test: registering";
}

foreach my $test (keys %disk_tests) {
    my $lsvpd_file = "resources/aix/lsvpd/$test";
    my $lsdev_file = "resources/aix/lsdev/$test-disk-$disk_tests{$test}->{type}";
    my $infos = GLPI::Agent::Task::Inventory::AIX::Storages::_getIndexedLsvpdInfos(file => $lsvpd_file);
    my @disks = GLPI::Agent::Task::Inventory::AIX::Storages::_getDisks(file => $lsdev_file, infos => $infos);
    cmp_deeply(\@disks, $disk_tests{$test}->{disks}, "disk extraction: $test");
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_) foreach @disks;
    } "$test: registering";
}

foreach my $test (keys %lspv_tests) {
    my $file = "resources/aix/lspv/$test";
    my $capacity = GLPI::Agent::Task::Inventory::AIX::Storages::_getVirtualCapacity(file => $file);
    cmp_deeply($capacity, $lspv_tests{$test}, "lspv parsing: $test");
}
