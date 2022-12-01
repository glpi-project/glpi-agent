#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::HPUX::Slots;

my %tests = (
    'hpux2-ioa' => [
        {
            NAME        => 'sba0',
            DESIGNATION => 'root.sba',
            DESCRIPTION => 'System Bus Adapter (1229)',
        }
    ],
    'hpux2-ba' => [
        {
            NAME        => 'pci_adapter0/0',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/1',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/2',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/3',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/3/1/0',
            DESIGNATION => 'root.sba.lba.PCItoPCI',
            DESCRIPTION => 'PCItoPCI Bridge',
        },
        {
            NAME        => 'pci_adapter0/4',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/5',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/6',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pdh250',
            DESIGNATION => 'root.pdh',
            DESCRIPTION => 'Core I/O Adapter',
        }
    ],
    'hpux1-ioa' => [
        {
            NAME        => 'sba0',
            DESIGNATION => 'root.sba',
            DESCRIPTION => 'System Bus Adapter (1229)',
        }
    ],
    'hpux1-ba' => [
        {
            NAME        => 'pci_adapter0/0',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/1',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/2',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/3',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/3/1/0',
            DESIGNATION => 'root.sba.lba.PCItoPCI',
            DESCRIPTION => 'PCItoPCI Bridge',
        },
        {
            NAME        => 'pci_adapter0/4',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/5',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pci_adapter0/6',
            DESIGNATION => 'root.sba.lba',
            DESCRIPTION => 'Local PCI-X Bus Adapter (122e)',
        },
        {
            NAME        => 'pdh250',
            DESIGNATION => 'root.pdh',
            DESCRIPTION => 'Core I/O Adapter',
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/hpux/ioscan/$test";
    my @slots = GLPI::Agent::Task::Inventory::HPUX::Slots::_getSlots(file => $file);
    cmp_deeply(\@slots, $tests{$test}, "$test ioscan parsing");
    lives_ok {
        $inventory->addEntry(section => 'SLOTS', entry => $_) foreach @slots;
    } "$test: registering";
}
