#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Virtualization::VirtualBox;
use GLPI::Agent::Tools::Virtualization;

my %tests = (
    sample1 => [
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Fusion-UsineRefav',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 855,
            UUID      => '03a37b40-31f0-4c10-8a92-472d02b02221',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Client-Leopard2',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 1024,
            UUID      => 'd2ba1d3d-f682-4e25-b5a7-47eea52253bc',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Client-Snow64',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 512,
            UUID      => '509c9563-05c7-4654-b8a4-ce7d639148bc',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Client-Win2k',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 256,
            UUID      => 'dba8762a-ed1e-4984-ba06-dad9ed981a5a',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'OpenSuse',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 512,
            UUID      => '6047a446-06fd-45ad-8829-cb2b7d81c8a2',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'OpenSolaris',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 768,
            UUID      => '201ca94e-66fb-4d3f-b2af-6d1b4746e77b',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Mandriva',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 512,
            UUID      => '46f9d625-923a-41fb-8518-53c58a041142',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'openbsd47',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 671,
            UUID      => '347850fa-1279-4678-89eb-19f53f1f021c',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'netbsd',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 64,
            UUID      => '4ddac902-a4f6-4ccb-a1a4-73dd6c90c1b2',
            VCPU      => 1
        }
    ],
    sample2 => [
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'FreeBSD8 i386',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_RUNNING,
            MEMORY    => 512,
            UUID      => 'd1857d13-a67f-4ba9-a3e6-101e42f59268',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Windows2000 (fusion agent)',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 512,
            UUID      => 'f8d4f838-aaa4-4f9b-b756-f95bc8d9cceb',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Centos',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 776,
            UUID      => '2cbb51b4-503c-4b5e-a6a5-878851a04658',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'windows 7 RU',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 512,
            UUID      => 'c404fff7-67bf-4b9c-95cc-19c6b27bcd5f',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Windows XP',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_RUNNING,
            MEMORY    => 512,
            UUID      => '3fd80a8f-ed78-4421-9192-c0af6f5f66d5',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'windowsxp01',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 256,
            UUID      => 'c7608d9d-c76c-4dab-8411-2784deb4eb1f',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'windowsxp02',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 256,
            UUID      => 'cd033191-26c3-49c9-afee-1e3affc933ee',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'debian10023',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 200,
            UUID      => 'ec43b1fc-0efc-487f-8188-a104473db0d5',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'debian10024',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 200,
            UUID      => 'd410a9a0-0b31-4bad-9a51-80ab37701d1d',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'MacOSX 10.6',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 1024,
            UUID      => '85b780f6-b3fd-44d3-bb94-d8583cd78770',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'windows xp RU',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 306,
            UUID      => 'fbc00535-0e8d-4955-8026-2bd50bf606e9',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Mandriva',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 512,
            UUID      => 'c43f39f2-a970-40a0-9435-7b09b218efdf',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Macos',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 1365,
            UUID      => 'd1fe6cfa-80c6-41ae-9f4b-2a15dbafcf2c',
            VCPU      => 1
        }
    ],
    sample3 => [
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Node 1 : Debian',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 256,
            UUID      => 'e8e1f52d-700b-4fe8-b024-db04550eaddc',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Node 2 : Debian',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 256,
            UUID      => '1922b52b-aa28-4d4a-b384-2d3429e3a6ad',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Node 3 : CentOS',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 256,
            UUID      => 'a93b30fb-c0f8-4dbf-b439-f6e26d923cf7',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Node 4 : CentOS',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 256,
            UUID      => '677daaa1-3e7a-441a-91be-449e02c82dd0',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'FormationCFengine',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 384,
            UUID      => 'b8b35683-eb17-4689-8213-6a46b28b139f',
            VCPU      => 1
        },
        {
            VMTYPE    => 'virtualbox',
            NAME      => 'Debian Maître - Squeeze',
            SUBSYSTEM => 'Oracle VM VirtualBox',
            STATUS    => STATUS_OFF,
            MEMORY    => 1024,
            UUID      => 'ab6afdd6-aa78-4a22-8fc9-02b471c9084c',
            VCPU      => 1
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/virtualization/vboxmanage/$test";
    my @machines = GLPI::Agent::Task::Inventory::Virtualization::VirtualBox::_parseVBoxManage(file => $file);
    cmp_deeply(\@machines, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'VIRTUALMACHINES', entry => $_)
            foreach @machines;
    } "$test: registering";
}
