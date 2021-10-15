#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::AIX::Slots;

my %tests = (
    'aix-5.3a' => [
        {
            NAME        => 'ent0:14108902',
            DESIGNATION => '2-Port 10/100/1000 Base-TX PCI-X Adapter (14108902)',
        },
        {
            NAME        => 'ent1:14108902',
            DESIGNATION => '2-Port 10/100/1000 Base-TX PCI-X Adapter (14108902)',
        },
        {
            NAME        => 'ide0:5a107512',
            DESIGNATION => 'ATA/IDE Controller Device',
        },
        {
            NAME        => 'lai0:14103302',
            DESIGNATION => 'GXT135P Graphics Adapter',
        },
        {
            NAME        => 'sa0:4f11c800',
            DESIGNATION => '2-Port Asynchronous EIA-232 PCI Adapter',
        },
        {
            NAME        => 'sa1:4f111100',
            DESIGNATION => 'IBM 8-Port EIA-232/RS-422A (PCI) Adapter',
        },
        {
            NAME        => 'sisscsia0:14106602',
            DESIGNATION => 'PCI-X Dual Channel Ultra320 SCSI Adapter',
        },
        {
            NAME        => 'usbhc0:33103500',
            DESIGNATION => 'USB Host Controller (33103500)',
        },
        {
            NAME        => 'usbhc1:33103500',
            DESIGNATION => 'USB Host Controller (33103500)',
        },
        {
            NAME        => 'vsa0:hvterm1',
            DESIGNATION => 'LPAR Virtual Serial Adapter',
        },
        {
            NAME        => 'vsa1:hvterm-protocol',
            DESIGNATION => 'LPAR Virtual Serial Adapter',
        },
        {
            NAME        => 'vsa2:hvterm-protocol',
            DESIGNATION => 'LPAR Virtual Serial Adapter',
        }
    ],
    'aix-5.3b' => [
        {
            NAME        => 'ent0:14101403',
            DESIGNATION => 'Gigabit Ethernet-SX PCI-X Adapter (14101403)',
        },
        {
            NAME        => 'ent1:14101403',
            DESIGNATION => 'Gigabit Ethernet-SX PCI-X Adapter (14101403)',
        },
        {
            NAME        => 'ent2:ibm_ech',
            DESIGNATION => 'EtherChannel / IEEE 802.3ad Link Aggregation',
        },
        {
            NAME        => 'ent3:eth',
            DESIGNATION => 'VLAN',
        },
        {
            NAME        => 'ent4:eth',
            DESIGNATION => 'VLAN',
        },
        {
            NAME        => 'sisioa0:14108d02',
            DESIGNATION => 'PCI-XDDR Dual Channel SAS RAID Adapter',
        },
        {
            NAME        => 'usbhc0:22106474',
            DESIGNATION => 'USB Host Controller (22106474)',
        },
        {
            NAME        => 'usbhc1:22106474',
            DESIGNATION => 'USB Host Controller (22106474)',
        },
        {
            NAME        => 'vsa0:hvterm1',
            DESIGNATION => 'LPAR Virtual Serial Adapter',
        }
    ],
    'aix-5.3c' => [
        {
            NAME        => 'ent0:ethernet',
            DESIGNATION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'ent1:ethernet',
            DESIGNATION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'ent2:IBM,l-lan',
            DESIGNATION => 'Virtual I/O Ethernet Adapter (l-lan)',
        },
        {
            NAME        => 'lhea0:IBM,lhea',
            DESIGNATION => 'Logical Host Ethernet Adapter (l-hea)',
        },
        {
            NAME        => 'vsa0:hvterm1',
            DESIGNATION => 'LPAR Virtual Serial Adapter',
        },
        {
            NAME        => 'vscsi0:IBM,v-scsi',
            DESIGNATION => 'Virtual SCSI Client Adapter',
        }
    ],
    'aix-6.1a' => [
        {
            NAME        => 'ent0:IBM,l-lan',
            DESIGNATION => 'Virtual I/O Ethernet Adapter (l-lan)',
        },
        {
            NAME        => 'ent1:ethernet',
            DESIGNATION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'ent2:ethernet',
            DESIGNATION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'fcs0:df1000fe',
            DESIGNATION => '4Gb FC PCI Express Adapter (df1000fe)',
        },
        {
            NAME        => 'fcs1:df1000fe',
            DESIGNATION => '4Gb FC PCI Express Adapter (df1000fe)',
        },
        {
            NAME        => 'fcs2:df1000fe',
            DESIGNATION => '4Gb FC PCI Express Adapter (df1000fe)',
        },
        {
            NAME        => 'fcs3:df1000fe',
            DESIGNATION => '4Gb FC PCI Express Adapter (df1000fe)',
        },
        {
            NAME        => 'fcs4:IBM,vfc-client',
            DESIGNATION => 'Virtual Fibre Channel Client Adapter',
        },
        {
            NAME        => 'lhea0:IBM,lhea',
            DESIGNATION => 'Logical Host Ethernet Adapter (l-hea)',
        },
        {
            NAME        => 'vsa0:hvterm1',
            DESIGNATION => 'LPAR Virtual Serial Adapter',
        },
        {
            NAME        => 'vscsi0:IBM,v-scsi',
            DESIGNATION => 'Virtual SCSI Client Adapter',
        },
        {
            NAME        => 'vscsi1:IBM,v-scsi',
            DESIGNATION => 'Virtual SCSI Client Adapter',
        }
    ],
    'aix-6.1b' => [
        {
            NAME        => 'ati0:02105e51',
            DESIGNATION => 'Native Display Graphics Adapter',
        },
        {
            NAME        => 'ent0:14106703',
            DESIGNATION => 'Gigabit Ethernet-SX PCI-X Adapter (14106703)',
        },
        {
            NAME        => 'ent1:14106703',
            DESIGNATION => 'Gigabit Ethernet-SX PCI-X Adapter (14106703)',
        },
        {
            NAME        => 'ent2:ethernet',
            DESIGNATION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'ent3:ethernet',
            DESIGNATION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'fcs0:77103224',
            DESIGNATION => 'PCI Express 4Gb FC Adapter (77103224)',
        },
        {
            NAME        => 'fcs1:77103224',
            DESIGNATION => 'PCI Express 4Gb FC Adapter (77103224)',
        },
        {
            NAME        => 'lhea0:IBM,lhea',
            DESIGNATION => 'Logical Host Ethernet Adapter (l-hea)',
        },
        {
            NAME        => 'mptsas0:00105000',
            DESIGNATION => 'SAS Expansion Card (00105000)',
        },
        {
            NAME        => 'sissas0:1410c102',
            DESIGNATION => 'PCI-X266 Planar 3Gb SAS Adapter',
        },
        {
            NAME        => 'usbhc0:33103500',
            DESIGNATION => 'USB Host Controller (33103500)',
        },
        {
            NAME        => 'usbhc1:33103500',
            DESIGNATION => 'USB Host Controller (33103500)',
        },
        {
            NAME        => 'usbhc2:3310e000',
            DESIGNATION => 'USB Enhanced Host Controller (3310e000)',
        },
        {
            NAME        => 'vsa0:hvterm1',
            DESIGNATION => 'LPAR Virtual Serial Adapter',
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/aix/lsdev/$test-adapter";
    my @slots = GLPI::Agent::Task::Inventory::AIX::Slots::_getSlots(file => $file);
    cmp_deeply(\@slots, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'SLOTS', entry => $_) foreach @slots;
    } "$test: registering";
}
