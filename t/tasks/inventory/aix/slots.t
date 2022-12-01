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
            NAME        => 'ent0',
            DESIGNATION => '14108902',
            DESCRIPTION => '2-Port 10/100/1000 Base-TX PCI-X Adapter (14108902)',
        },
        {
            NAME        => 'ent1',
            DESIGNATION => '14108902',
            DESCRIPTION => '2-Port 10/100/1000 Base-TX PCI-X Adapter (14108902)',
        },
        {
            NAME        => 'ide0',
            DESIGNATION => '5a107512',
            DESCRIPTION => 'ATA/IDE Controller Device',
        },
        {
            NAME        => 'lai0',
            DESIGNATION => '14103302',
            DESCRIPTION => 'GXT135P Graphics Adapter',
        },
        {
            NAME        => 'sa0',
            DESIGNATION => '4f11c800',
            DESCRIPTION => '2-Port Asynchronous EIA-232 PCI Adapter',
        },
        {
            NAME        => 'sa1',
            DESIGNATION => '4f111100',
            DESCRIPTION => 'IBM 8-Port EIA-232/RS-422A (PCI) Adapter',
        },
        {
            NAME        => 'sisscsia0',
            DESIGNATION => '14106602',
            DESCRIPTION => 'PCI-X Dual Channel Ultra320 SCSI Adapter',
        },
        {
            NAME        => 'usbhc0',
            DESIGNATION => '33103500',
            DESCRIPTION => 'USB Host Controller (33103500)',
        },
        {
            NAME        => 'usbhc1',
            DESIGNATION => '33103500',
            DESCRIPTION => 'USB Host Controller (33103500)',
        },
        {
            NAME        => 'vsa0',
            DESIGNATION => 'hvterm1',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
        },
        {
            NAME        => 'vsa1',
            DESIGNATION => 'hvterm-protocol',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
        },
        {
            NAME        => 'vsa2',
            DESIGNATION => 'hvterm-protocol',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
        }
    ],
    'aix-5.3b' => [
        {
            NAME        => 'ent0',
            DESIGNATION => '14101403',
            DESCRIPTION => 'Gigabit Ethernet-SX PCI-X Adapter (14101403)',
        },
        {
            NAME        => 'ent1',
            DESIGNATION => '14101403',
            DESCRIPTION => 'Gigabit Ethernet-SX PCI-X Adapter (14101403)',
        },
        {
            NAME        => 'ent2',
            DESIGNATION => 'ibm_ech',
            DESCRIPTION => 'EtherChannel / IEEE 802.3ad Link Aggregation',
        },
        {
            NAME        => 'ent3',
            DESIGNATION => 'eth',
            DESCRIPTION => 'VLAN',
        },
        {
            NAME        => 'ent4',
            DESIGNATION => 'eth',
            DESCRIPTION => 'VLAN',
        },
        {
            NAME        => 'sisioa0',
            DESIGNATION => '14108d02',
            DESCRIPTION => 'PCI-XDDR Dual Channel SAS RAID Adapter',
        },
        {
            NAME        => 'usbhc0',
            DESIGNATION => '22106474',
            DESCRIPTION => 'USB Host Controller (22106474)',
        },
        {
            NAME        => 'usbhc1',
            DESIGNATION => '22106474',
            DESCRIPTION => 'USB Host Controller (22106474)',
        },
        {
            NAME        => 'vsa0',
            DESIGNATION => 'hvterm1',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
        }
    ],
    'aix-5.3c' => [
        {
            NAME        => 'ent0',
            DESIGNATION => 'ethernet',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'ent1',
            DESIGNATION => 'ethernet',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'ent2',
            DESIGNATION => 'IBM,l-lan',
            DESCRIPTION => 'Virtual I/O Ethernet Adapter (l-lan)',
        },
        {
            NAME        => 'lhea0',
            DESIGNATION => 'IBM,lhea',
            DESCRIPTION => 'Logical Host Ethernet Adapter (l-hea)',
        },
        {
            NAME        => 'vsa0',
            DESIGNATION => 'hvterm1',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
        },
        {
            NAME        => 'vscsi0',
            DESIGNATION => 'IBM,v-scsi',
            DESCRIPTION => 'Virtual SCSI Client Adapter',
        }
    ],
    'aix-6.1a' => [
        {
            NAME        => 'ent0',
            DESIGNATION => 'IBM,l-lan',
            DESCRIPTION => 'Virtual I/O Ethernet Adapter (l-lan)',
        },
        {
            NAME        => 'ent1',
            DESIGNATION => 'ethernet',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'ent2',
            DESIGNATION => 'ethernet',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'fcs0',
            DESIGNATION => 'df1000fe',
            DESCRIPTION => '4Gb FC PCI Express Adapter (df1000fe)',
        },
        {
            NAME        => 'fcs1',
            DESIGNATION => 'df1000fe',
            DESCRIPTION => '4Gb FC PCI Express Adapter (df1000fe)',
        },
        {
            NAME        => 'fcs2',
            DESIGNATION => 'df1000fe',
            DESCRIPTION => '4Gb FC PCI Express Adapter (df1000fe)',
        },
        {
            NAME        => 'fcs3',
            DESIGNATION => 'df1000fe',
            DESCRIPTION => '4Gb FC PCI Express Adapter (df1000fe)',
        },
        {
            NAME        => 'fcs4',
            DESIGNATION => 'IBM,vfc-client',
            DESCRIPTION => 'Virtual Fibre Channel Client Adapter',
        },
        {
            NAME        => 'lhea0',
            DESIGNATION => 'IBM,lhea',
            DESCRIPTION => 'Logical Host Ethernet Adapter (l-hea)',
        },
        {
            NAME        => 'vsa0',
            DESIGNATION => 'hvterm1',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
        },
        {
            NAME        => 'vscsi0',
            DESIGNATION => 'IBM,v-scsi',
            DESCRIPTION => 'Virtual SCSI Client Adapter',
        },
        {
            NAME        => 'vscsi1',
            DESIGNATION => 'IBM,v-scsi',
            DESCRIPTION => 'Virtual SCSI Client Adapter',
        }
    ],
    'aix-6.1b' => [
        {
            NAME        => 'ati0',
            DESIGNATION => '02105e51',
            DESCRIPTION => 'Native Display Graphics Adapter',
        },
        {
            NAME        => 'ent0',
            DESIGNATION => '14106703',
            DESCRIPTION => 'Gigabit Ethernet-SX PCI-X Adapter (14106703)',
        },
        {
            NAME        => 'ent1',
            DESIGNATION => '14106703',
            DESCRIPTION => 'Gigabit Ethernet-SX PCI-X Adapter (14106703)',
        },
        {
            NAME        => 'ent2',
            DESIGNATION => 'ethernet',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'ent3',
            DESIGNATION => 'ethernet',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
        },
        {
            NAME        => 'fcs0',
            DESIGNATION => '77103224',
            DESCRIPTION => 'PCI Express 4Gb FC Adapter (77103224)',
        },
        {
            NAME        => 'fcs1',
            DESIGNATION => '77103224',
            DESCRIPTION => 'PCI Express 4Gb FC Adapter (77103224)',
        },
        {
            NAME        => 'lhea0',
            DESIGNATION => 'IBM,lhea',
            DESCRIPTION => 'Logical Host Ethernet Adapter (l-hea)',
        },
        {
            NAME        => 'mptsas0',
            DESIGNATION => '00105000',
            DESCRIPTION => 'SAS Expansion Card (00105000)',
        },
        {
            NAME        => 'sissas0',
            DESIGNATION => '1410c102',
            DESCRIPTION => 'PCI-X266 Planar 3Gb SAS Adapter',
        },
        {
            NAME        => 'usbhc0',
            DESIGNATION => '33103500',
            DESCRIPTION => 'USB Host Controller (33103500)',
        },
        {
            NAME        => 'usbhc1',
            DESIGNATION => '33103500',
            DESCRIPTION => 'USB Host Controller (33103500)',
        },
        {
            NAME        => 'usbhc2',
            DESIGNATION => '3310e000',
            DESCRIPTION => 'USB Enhanced Host Controller (3310e000)',
        },
        {
            NAME        => 'vsa0',
            DESIGNATION => 'hvterm1',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
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
