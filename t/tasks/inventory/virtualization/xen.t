#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Tools qw(getAllLines);
use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Virtualization::Xen;
use GLPI::Agent::Tools::Virtualization;

my %tests_xm_list = (
    xm_list => [
        {
            NAME      => 'Fedora3',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'xen',
            MEMORY    => '128',
            VCPU      => '1'
        },
        {
            NAME      => 'Fedora4',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '128',
            VCPU      => '1'
        },
        {
            NAME      => 'Mandrake2006',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '128',
            VCPU      => '1'
        },
        {
            NAME      => 'Mandrake10.2',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '128',
            VCPU      => '1'
        },
        {
            NAME      => 'Suse9.2',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '100',
            VCPU      => '1'
        }
    ],
    xm_list2 => [
        {
            NAME      => 'lvm0001',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '1'
        },
        {
            NAME      => 'lvm0002',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0003',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0004',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0005',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '2'
        },
        {
            NAME      => 'lvm0006',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '2'
        },
        {
            NAME      => 'lvm0007',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '1024',
            VCPU      => '1'
        },
        {
            NAME      => 'lvm0008',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '2048',
            VCPU      => '1'
        },
        {
            NAME      => 'lvm0009',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0010',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'xen',
            MEMORY    => '8192',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0011',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '32'
        },
        {
            NAME      => 'lvm0012',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '32768',
            VCPU      => '24'
        },
        {
            NAME      => 'lvm0013',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '32768',
            VCPU      => '24'
        },
        {
            NAME      => 'lvm0014',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '32768',
            VCPU      => '16'
        },
        {
            NAME      => 'lvm0015',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0016',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '8192',
            VCPU      => '2'
        },
        {
            NAME      => 'lvm0017',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0018',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '32768',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0019',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0020',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0021',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0022',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '8192',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0023',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0024',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '32768',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0025',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '2048',
            VCPU      => '1'
        },
        {
            NAME      => 'lvm0026',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '16'
        },
        {
            NAME      => 'lvm0027',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '16'
        },
        {
            NAME      => 'lvm0028',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0029',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0030',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '4'
        },
        {
            NAME      => 'lvm0031',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '32768',
            VCPU      => '12'
        },
        {
            NAME      => 'lvm0032',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '32768',
            VCPU      => '16'
        },
        {
            NAME      => 'lvm0033',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '2'
        },
        {
            NAME      => 'lvm0034',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '32768',
            VCPU      => '16'
        },
        {
            NAME      => 'lvm0035',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '2'
        },
        {
            NAME      => 'lvm0036',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '24576',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0037',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '2'
        },
        {
            NAME      => 'lvm0038',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '8192',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0039',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0041',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0042',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0043',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '16'
        },
        {
            NAME      => 'lvm0044',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '1024',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0045',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0046',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '16384',
            VCPU      => '8'
        },
        {
            NAME      => 'lvm0047',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '65536',
            VCPU      => '16'
        },
        {
            NAME      => 'lvm0048',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_OFF,
            VMTYPE    => 'xen',
            MEMORY    => '12288',
            VCPU      => '12'
        },
        {
            NAME      => 'lvm0049',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '2048',
            VCPU      => '2'
        },
        {
            NAME      => 'lvm0050',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'xen',
            MEMORY    => '8192',
            VCPU      => '4'
        }
    ],
    xl_list => [
        {
            NAME      => 'vm1',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '20480',
            VCPU      => '4'
        },
        {
            NAME      => 'vm2',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '4096',
            VCPU      => '2'
        }
    ],
    xl_list2 => [
        {
            NAME      => 'SQL LUBSS227',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '1536',
            VCPU      => '2'
        },
        {
            NAME      => 'SQL LUBSS239',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '1024',
            VCPU      => '1'
        },
        {
            NAME      => 'SQL LUBSS237',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'xen',
            MEMORY    => '2048',
            VCPU      => '4'
        },
        {
            NAME      => 'SQL LUBSS235',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '2047',
            VCPU      => '4'
        },
        {
            NAME      => 'IIS LUBSIIS12',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '2048',
            VCPU      => '4'
        },
        {
            NAME      => 'SQL LUBSS245',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '1024',
            VCPU      => '2'
        },
        {
            NAME      => 'SQL LUBSS238',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '2048',
            VCPU      => '2'
        },
        {
            NAME      => 'SQL LUBSS242',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'xen',
            MEMORY    => '2000',
            VCPU      => '4'
        },
        {
            NAME      => 'SQL LUBSS218',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '2000',
            VCPU      => '2'
        },
        {
            NAME      => 'SQL REL LUBSS223',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'xen',
            MEMORY    => '6000',
            VCPU      => '4'
        },
        {
            NAME      => 'SQL LUBSS230',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '1535',
            VCPU      => '4'
        },
        {
            NAME      => 'SQL REL LUBSS215',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '3000',
            VCPU      => '4'
        },
        {
            NAME      => 'SQL REL LUBSS221',
            SUBSYSTEM => 'xm',
            STATUS    => STATUS_BLOCKED,
            VMTYPE    => 'xen',
            MEMORY    => '2048',
            VCPU      => '4'
        }
    ]
);


my %tests_getUUID = (
    'xm_list_-l_vmname' => '0004fb00-0006-0000-4acc-3678187fb85c',
    'xl_list_-v_vmname' => '482e6c75-090e-4cf2-9c06-de39c824cbe4'
);

plan tests =>
(2 * scalar keys %tests_xm_list) +
(scalar keys %tests_getUUID)     +
1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests_xm_list) {
    my @lines = getAllLines(file => "resources/virtualization/xm/$test");
    my @machines = GLPI::Agent::Task::Inventory::Virtualization::Xen::_getVirtualMachines(lines => \@lines);
    cmp_deeply(\@machines, $tests_xm_list{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'VIRTUALMACHINES', entry => $_)
        foreach @machines;
    } "$test: registering";
}

foreach my $test (keys %tests_getUUID) {
    my $file = "resources/virtualization/xm/$test";
    my $uuid = GLPI::Agent::Task::Inventory::Virtualization::Xen::_getUUID(file => $file);
    cmp_deeply($uuid, $tests_getUUID{$test}, $test);
}
