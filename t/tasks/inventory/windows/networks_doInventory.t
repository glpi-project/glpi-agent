#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More tests => 6;
use Test::MockModule;

use GLPI::Agent::Inventory;
use GLPI::Agent::Task::Inventory::Win32::Networks;

# Mock getInterfaces to return our anonymized network adapters
my $mock_win32 = Test::MockModule->new('GLPI::Agent::Tools::Win32');
$mock_win32->mock('getInterfaces', sub {
    return (
        {
            DESCRIPTION => 'Ethernet',
            MACADDR     => '00:11:22:33:44:55',
            MANUFACTURER => 'Microsoft',
            MODEL       => 'Generic Gigabit Ethernet',
            PCIID       => '14e4:165f:05e5:1028',
            PNPDEVICEID => 'PCI\VEN_14E4&DEV_165F&SUBSYS_05E51028&REV_00\000020474790784200',
            SPEED       => '1000',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Ethernet 2',
            MACADDR     => '00:11:22:33:44:66',
            MANUFACTURER => 'Microsoft',
            MODEL       => 'Generic Gigabit Ethernet',
            PCIID       => '14e4:165f:05e5:1028',
            PNPDEVICEID => 'PCI\VEN_14E4&DEV_165F&SUBSYS_05E51028&REV_00\000020474790784401',
            SPEED       => '1000',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'LoadBalance',
            IPADDRESS   => '192.168.1.100',
            IPGATEWAY   => '192.168.1.1',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '192.168.1.0',
            MACADDR     => '00:11:22:33:44:55',
            MANUFACTURER => 'Microsoft',
            MODEL       => 'Microsoft Network Adapter Multiplexor Driver',
            PNPDEVICEID => 'COMPOSITEBUS\MS_IMPLAT_MP\{00000000-0000-0000-0000-000000000000}',
            SPEED       => '2000',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 1
        }
    );
});

# Mock getRegistryKey to avoid failures
$mock_win32->mock('getRegistryKey', sub { return {}; });

my $inventory = GLPI::Agent::Inventory->new();

GLPI::Agent::Task::Inventory::Win32::Networks::doInventory(
    inventory => $inventory,
    datadir   => 'share'
);

my @networks = $inventory->getElements('NETWORKS');
is(scalar @networks, 3, 'Found 3 network interfaces');

# Check Ethernet 1 (PCI Manufacturer replaced)
is($networks[0]->{DESCRIPTION}, 'Ethernet', 'First interface is Ethernet');
is($networks[0]->{MANUFACTURER}, 'Broadcom Inc. and subsidiaries', 'Hardware Manufacturer accurately overwritten using PCIID');

# Check Ethernet 2 (PCI Manufacturer replaced)
is($networks[1]->{MANUFACTURER}, 'Broadcom Inc. and subsidiaries', 'Hardware Manufacturer accurately overwritten using PCIID for second interface');

# Check LoadBalance (No PCIID, remains Microsoft)
is($networks[2]->{MANUFACTURER}, 'Microsoft', 'Virtual LoadBalance interface retains original Microsoft manufacturer');
is($networks[2]->{VIRTUALDEV}, 1, 'Virtual LoadBalance interface is correctly identified as a virtualdev');
