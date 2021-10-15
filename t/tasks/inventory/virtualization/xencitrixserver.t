#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Virtualization::XenCitrixServer;

my %tests_getVirtualMachines = (
    'xenserver-6.2_vm_list' => [
        {
            UUID      => 'a444ab5d-d1fc-f1a5-5ab4-3f0c3c07352e',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        },
        {
            UUID      => '7aa76a40-5e05-35eb-f275-e0f6c2c13d8f',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        },
        {
            UUID      => 'a45a98b0-7e85-45d9-8a40-5b1dd0a91646',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        },
        {
            UUID      => 'ecfeaa60-07cf-b710-30c2-d2f6a4cdb152',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        },
        {
            UUID      => '1f9e34f8-285b-4fa4-b81c-fea9877adf08',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        },
        {
            UUID      => 'aa73f25f-7bb9-0bcd-9d8a-3790d8196d2c',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        },
        {
            UUID      => '1b3907d8-7987-9e5f-7e0c-0d0e3885b87b',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        },
        {
            UUID      => '7b89788c-8282-431b-b864-a8e2d16d21ef',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        },
        {
            UUID      => 'd00720df-0dcb-5259-9d8d-4bf2fc3a272c',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        },
        {
            UUID      => 'aad6e924-f255-f5f0-710c-be6b8aefd1dd',
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen'
        }
    ],
    'xe_none' => []
);

my %tests_xe_vm_params = (
    'xenserver-6.2_vm_param_list_001' => {
        NAME      => 'core-02',
        STATUS    => 'running',
        MEMORY    => '20480',
        VCPU      => '16'
    },
    'xenserver-6.2_vm_param_list_002' => {
        NAME      => 'GLPI',
        STATUS    => 'running',
        MEMORY    => '2048',
        VCPU      => '2',
        COMMENT   => 'Resource Manager'
    },
    'xenserver-6.2_vm_param_list_003' => undef,
    'xenserver-6.2_vm_param_list_004' => {
        NAME      => 'OCS Inventory',
        STATUS    => 'shutdown',
        MEMORY    => '0',
        VCPU      => '0'
    },
    'xenserver-6.2_vm_param_list_005' => undef,
    'xenserver-6.2_vm_param_list_006' => {
        NAME      => 'JController-01',
        STATUS    => 'running',
        MEMORY    => '8192',
        VCPU      => '4',
        COMMENT   => 'VM from knife-xapi as JController-01 by mool'
    },
    'xenserver-6.2_vm_param_list_007' => {
        NAME      => 'Gitlab',
        STATUS    => 'running',
        MEMORY    => '2048',
        VCPU      => '2'
    },
    'xenserver-6.2_vm_param_list_008' => undef,
    'xenserver-6.2_vm_param_list_009' => {
        NAME      => 'ns2',
        STATUS    => 'running',
        MEMORY    => '1024',
        VCPU      => '2',
        COMMENT   => 'VM from knife-xapi as ns2 by mool'
    },
    'xenserver-6.2_vm_param_list_010' => {
        NAME      => 'site-test',
        STATUS    => 'running',
        MEMORY    => '1024',
        VCPU      => '1',
        COMMENT   => 'VM from knife-xapi as site-test by mool'
    },
);

plan tests => 1 + (scalar keys %tests_getVirtualMachines)
            + (scalar keys %tests_xe_vm_params);

foreach my $test (keys %tests_getVirtualMachines) {
    my $file = "resources/virtualization/xe/$test";
    my @vms = GLPI::Agent::Task::Inventory::Virtualization::XenCitrixServer::_getVirtualMachines(file => $file);
    cmp_deeply(\@vms, $tests_getVirtualMachines{$test}, $test);
}

foreach my $test (keys %tests_xe_vm_params) {
    my $file = "resources/virtualization/xe/$test";
    my $machine = GLPI::Agent::Task::Inventory::Virtualization::XenCitrixServer::_getVirtualMachine(file => $file);
    cmp_deeply($machine, $tests_xe_vm_params{$test}, $test);
}
