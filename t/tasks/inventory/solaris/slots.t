#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Solaris::Slots;

my %tests = (
    'sample1' => [
        {
            NAME        => 'MB/NET0',
            DESIGNATION => 'network-pciex8086,105e',
            DESCRIPTION => 'PCIE'
        },
        {
            NAME        => 'MB/NET1',
            DESIGNATION => 'network-pciex8086,105e',
            DESCRIPTION => 'PCIE'
        },
        {
            NAME        => 'MB/NET2',
            DESIGNATION => 'network-pciex8086,105e',
            DESCRIPTION => 'PCIE'
        },
            {
            NAME        => 'MB/NET3',
            DESIGNATION => 'network-pciex8086,105e',
            DESCRIPTION => 'PCIE'
        },
        {
            NAME        => 'MB/SASHBA',
            DESIGNATION => 'scsi-pciex1000,58',
            DESCRIPTION => 'PCIE'
        },
        {
            NAME        => 'MB/RISER0/PCIE0',
            DESIGNATION => 'SUNW,qlc-pciex1077,2432',
            DESCRIPTION => 'PCIE'
        },
        {
            NAME        => 'MB',
            DESIGNATION => 'usb-pciclass,0c0310',
            DESCRIPTION => 'PCIX'
        },
        {
            NAME        => 'MB',
            DESIGNATION => 'usb-pciclass,0c0310',
            DESCRIPTION => 'PCIX'
        },
        {
            NAME        => 'MB',
            DESIGNATION => 'usb-pciclass,0c0320',
            DESCRIPTION => 'PCIX'
        }
    ],
    'sample2' => [
        {
            NAME        => 1,
            DESCRIPTION => 'PCI',
            DESIGNATION => 'scsi-pci1000,30.1000.10c0.8/disk+',
        },
        {
            NAME        => 1,
            DESCRIPTION => 'PCI',
            DESIGNATION => 'scsi-pci1000,30.1000.10c0.8/disk+',
        },
        {
            NAME        => 0,
            DESCRIPTION => 'PCI',
            DESIGNATION => 'scsi-pci1000,30.1000.10c0.8/disk+',
        },
        {
            NAME        => 0,
            DESCRIPTION => 'PCI',
            DESIGNATION => 'scsi-pci1000,30.1000.10c0.8/disk+',
        },
        {
            NAME        => 5,
            DESCRIPTION => 'PCI',
            DESIGNATION => 'SUNW,XVR-100',
        },
    ],
    'sample3' => [
        {
            NAME        => 1,
            STATUS      => 'free',
            DESCRIPTION => 'PCI Express',
            DESIGNATION => 'PCIExp SLOT0'
        },
        {
            NAME        => 2,
            STATUS      => 'free',
            DESCRIPTION => 'PCI Express',
            DESIGNATION => 'PCIExp SLOT1'
        },
        {
            NAME        => 3,
            STATUS      => 'free',
            DESCRIPTION => 'PCI Express',
            DESIGNATION => 'PCIExp SLOT2'
        },
    ],
    'sample4' => [
        {
            NAME        => 1,
            STATUS      => 'free',
            DESCRIPTION => 'PCI Express',
            DESIGNATION => 'PCIE1'
        },
    ],
    'sample5' => [
        {
            NAME        => 0,
            STATUS      => undef,
            DESCRIPTION => 'ISA',
            DESIGNATION => 'ISA Slot J8'
        },
        {
            NAME        => 0,
            STATUS      => undef,
            DESCRIPTION => 'ISA',
            DESIGNATION => 'ISA Slot J9'
        },
        {
            NAME        => 0,
            STATUS      => undef,
            DESCRIPTION => 'ISA',
            DESIGNATION => 'ISA Slot J10'
        },
        {
            NAME        => 1,
            STATUS      => 'used',
            DESCRIPTION => 'PCI',
            DESIGNATION => 'PCI Slot J11'
        },
        {
            NAME        => 2,
            STATUS      => 'used',
            DESCRIPTION => 'PCI',
            DESIGNATION => 'PCI Slot J12'
        },
        {
            NAME        => 3,
            STATUS      => 'used',
            DESCRIPTION => 'PCI',
            DESIGNATION => 'PCI Slot J13'
        },
        {
            NAME        => 4,
            STATUS      => 'free',
            DESCRIPTION => 'PCI',
            DESIGNATION => 'PCI Slot J14'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/solaris/prtdiag/$test";
    my @slots = GLPI::Agent::Task::Inventory::Solaris::Slots::_getSlots(file => $file);
    cmp_deeply(\@slots, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'SLOTS', entry => $_) foreach @slots;
    } "$test: registering";
}
