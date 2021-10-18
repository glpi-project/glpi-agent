#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;
use Test::MockModule;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Virtualization::Virtuozzo;
use GLPI::Agent::Tools::Virtualization;

my %tests = (
    sample1 => {
        ctid_template   => 'sample1-ctid-conf',
        expected        => [
            {
                VMTYPE    => 'virtuozzo',
                NAME      => 'vz1.mydomain.com',
                SUBSYSTEM => 'debian-8.0-x86_64-minimal',
                STATUS    => STATUS_RUNNING,
                MEMORY    => '8000000',
                UUID      => 'fakeUUID-101',
                VCPU      => 0
            },
            {
                VMTYPE    => 'virtuozzo',
                NAME      => 'vz2.mydomain.com',
                SUBSYSTEM => 'debian-8.0-x86_64-minimal',
                STATUS    => STATUS_RUNNING,
                MEMORY    => '8000000',
                UUID      => 'fakeUUID-102',
                VCPU      => 0
            },
            {
                VMTYPE    => 'virtuozzo',
                NAME      => 'vz3.mydomain.com',
                SUBSYSTEM => 'debian-8.0-x86_64-minimal',
                STATUS    => STATUS_RUNNING,
                MEMORY    => '8000000',
                UUID      => 'fakeUUID-103',
                MAC       => '52:54:00:95:1f:77',
                VCPU      => 0
            },
            {
                VMTYPE    => 'virtuozzo',
                NAME      => 'vz4.mydomain.com',
                SUBSYSTEM => 'debian-8.0-x86_64-minimal',
                STATUS    => STATUS_OFF,
                MEMORY    => '8000000',
                UUID      => 'fakeUUID-104',
                VCPU      => 0
            }
        ]
    },
    sample2 => {
        ctid_template   => 'sample2-ctid-conf',
        expected        => [
            {
                MAC         => '00:18:51:5e:cc:ad',
                MEMORY      => 512,
                NAME        => 'info',
                STATUS      => 'running',
                SUBSYSTEM   => 'debian-6.0.2-amd64',
                UUID        => 'fakeUUID-136',
                VCPU        => 0,
                VMTYPE      => 'virtuozzo'
            },
            {
                MAC         => '00:18:51:9a:87:03',
                MEMORY      => 512,
                NAME        => 'dns1',
                STATUS      => 'running',
                SUBSYSTEM   => 'debian-4.0-i386-minimal',
                UUID        => 'fakeUUID-8102',
                VCPU        => 0,
                VMTYPE      => 'virtuozzo'
            },
            {
                MAC         => '00:18:51:4a:b6:9d',
                MEMORY      => 512,
                NAME        => 'surveys',
                STATUS      => 'running',
                SUBSYSTEM   => 'debian-4.0-i386-minimal',
                UUID        => 'fakeUUID-21179',
                VCPU        => 0,
                VMTYPE      => 'virtuozzo'
            },
            {
                MAC         => '00:18:51:38:b2:0f/00:18:51:65:86:c3',
                MEMORY      => 512,
                NAME        => 'release-notes.mobiletouch-fmcg.c',
                STATUS      => 'running',
                SUBSYSTEM   => 'debian-7.8-x86_64',
                UUID        => 'fakeUUID-208185',
                VCPU        => 0,
                VMTYPE      => 'virtuozzo'
            },
            {
                MAC         => '00:18:51:6f:c7:67',
                MEMORY      => 512,
                NAME        => 'cas-erpavp',
                STATUS      => 'running',
                SUBSYSTEM   => 'debian-8.1-x86_64',
                UUID        => 'fakeUUID-1951898610',
                VCPU        => 0,
                VMTYPE      => 'virtuozzo'
            }
        ]
    }
);

plan tests => scalar(keys(%tests)) + 1;

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Virtualization::Virtuozzo'
);

foreach my $test (keys %tests) {
    my $file = "resources/virtualization/virtuozzo/$test";

    my $inventory = GLPI::Test::Inventory->new();
    # Set a fake UUID as host UUID as used to create VM UUID
    $inventory->setHardware({ UUID => "fakeUUID" });

    $module->mock(
        '_getMACs',
        sub {
            my (%params) = @_;
            # Outputs of 'ip -0 a' could be found in resources like
            # resources/virtualization/virtuozzo/sample1-getmac-101
            my $file = $file . "-getmac-" . $params{ctid};
            return unless -s $file;
            return &{$module->original('_getMACs')}(
                file    => $file,
                %params
            );
        }
    );

    GLPI::Agent::Task::Inventory::Virtualization::Virtuozzo::doInventory(
        file            => $file,
        inventory       => $inventory,
        ctid_template   => "resources/virtualization/virtuozzo/".$tests{$test}->{ctid_template}
    );
    cmp_deeply($inventory->{content}->{VIRTUALMACHINES}, $tests{$test}->{expected}, "$test: virtuozzo inventory");
}
