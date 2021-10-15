#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Virtualization::Libvirt;
use GLPI::Agent::Tools::Virtualization;

my %list_tests = (
    list1 => [
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vm1',
            STATUS    => STATUS_RUNNING,
        },
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vm2',
            STATUS    => STATUS_RUNNING,
        },
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vm-ad',
            STATUS    => STATUS_RUNNING,
        },
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vm-ts',
            STATUS    => STATUS_RUNNING,
        },
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vm3',
            STATUS    => STATUS_RUNNING,
        },
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vm4',
            STATUS    => STATUS_RUNNING,
        },
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vm5',
            STATUS    => STATUS_RUNNING,
        },
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vm6-ws1',
            STATUS    => STATUS_RUNNING,
        },
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vml3',
            STATUS    => STATUS_RUNNING,
        },
        {
            VMTYPE    => 'libvirt',
            NAME      => 'vm-srv-net1',
            STATUS    => STATUS_OFF,
        }
    ],
    list2 => [
        {
            VMTYPE    => 'libvirt',
            NAME      => 'Debian_Squeeze_64_bits',
            STATUS    => STATUS_RUNNING,
        }
    ],
);

my %dumpxml_tests = (
    dumpxml1 => {
          memory => '524',
          vmtype => 'kvm',
          uuid    => 'd0f1baf3-ac9d-e828-619f-91f074c8c6c4',
          vcpu    => '1'
    },
    dumpxml2 => {
          memory => '4194',
          vmtype => 'kvm',
          uuid   => '5e3884eb-0caa-194b-cd17-3d9ca1b20c3b',
          vcpu   => '4'
    },
    dumpxml3 => {
          memory => '2097',
          vmtype => 'kvm',
          uuid   => 'aee61d6a-0c2f-f8b6-5246-7c555d803a7d',
          vcpu   => '2'
    },
    dumpxml4 => {
          memory => 2147,
          vmtype => 'kvm',
          uuid   => 'a28ff943-8d89-38ee-fd28-1e675142951c',
          vcpu   => '1'
    },
    dumpxml5_lxc => {
          memory => 500,
          vmtype => 'lxc',
          uuid   => '8e790dce-d6b5-4575-a765-c8cde17298d8',
          vcpu   => '1'
    },
);


plan tests =>
    (2 * scalar keys %list_tests) +
    (scalar keys %dumpxml_tests)  +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %list_tests) {
    my $file = "resources/virtualization/virsh/$test";
    my @machines = GLPI::Agent::Task::Inventory::Virtualization::Libvirt::_parseList(file => $file);
    cmp_deeply(\@machines, $list_tests{$test}, "virst list parsing: $test");
    lives_ok {
        $inventory->addEntry(section => 'VIRTUALMACHINES', entry => $_)
            foreach @machines;
    } "$test: registering";
}

foreach my $test (keys %dumpxml_tests) {
    my $file = "resources/virtualization/virsh/$test";
    my %infos = GLPI::Agent::Task::Inventory::Virtualization::Libvirt::_parseDumpxml(file => $file);
    cmp_deeply(\%infos, $dumpxml_tests{$test}, "virsh dumpxml parsing: $test");
}
