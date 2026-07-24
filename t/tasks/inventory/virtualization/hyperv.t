#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More;
use UNIVERSAL::require;

use GLPI::Agent::Inventory;
use GLPI::Test::Utils;
use GLPI::Agent::Tools::Virtualization;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

Test::NoWarnings->use();

GLPI::Agent::Task::Inventory::Virtualization::HyperV->require();

my %tests = (
    'unknown' => [
        {
            VMTYPE    => 'HyperV',
            SUBSYSTEM => 'MS HyperV',
            NAME      => 'vmw7cainf295537',
            STATUS    => STATUS_RUNNING,
            UUID      => undef,
            VCPU      => undef,
            MEMORY    => undef,
        },
        {
            VMTYPE    => 'HyperV',
            SUBSYSTEM => 'MS HyperV',
            NAME      => 'COLETA_FABIANO',
            STATUS    => STATUS_RUNNING,
            UUID      => undef,
            VCPU      => undef,
            MEMORY    => undef,
        },
        {
            SUBSYSTEM => 'MS HyperV',
            VMTYPE    => 'HyperV',
            NAME      => 'W2012',
            STATUS    => STATUS_OFF,
            UUID      => undef,
            VCPU      => undef,
            MEMORY    => undef,
        }
    ],
    '2008' => [
        {
            VMTYPE    => 'HyperV',
            SUBSYSTEM => 'MS HyperV',
            NAME      => 'vm-0450-glpi',
            STATUS    => STATUS_OFF,
            UUID      => undef,
            VCPU      => 2,
            MEMORY    => 2048,
            SERIAL    => '2008-SN-0001',
            NETWORKS  => [
                { DESCRIPTION => 'Network Adapter', MACADDR => '00:11:22:AA:BB:01' },
            ],
            DRIVES  => [
                { VOLUMN => 'C:\VMs\vm-disco.vhdx',           TOTAL => 102400 },
                { VOLUMN => '\\\\nas01\VMs\vm-datos.vhdx',    TOTAL => 512000 },
                { VOLUMN => '\\\\nas02\C$\VMs\vm-admin.vhdx', TOTAL =>  20480 },
            ],
        },
    ],
    'qa' => [
        {
            VMTYPE          => 'HyperV',
            SUBSYSTEM       => 'MS HyperV',
            NAME            => 'vm2',
            STATUS          => STATUS_RUNNING,
            UUID            => undef,
            VCPU            => 4,
            MEMORY          => 2048,
            SERIAL          => 'QA-SN-0002',
            NETWORKS        => [
                { DESCRIPTION => 'Network Adapter',   MACADDR => '00:11:22:AA:BB:02' },
                { DESCRIPTION => 'Network Adapter 2', MACADDR => 'DE:AD:BE:EF:00:02' },
            ],
            DRIVES        => [
                { VOLUMN => 'C:\HyperV\vm2.vhdx', TOTAL => 12288 },
            ],
            IPADDRESS       => '172.25.2.239',
            OPERATINGSYSTEM => { FULL_NAME => 'Ubuntu 6.8.0' },
        },
        {
            VMTYPE    => 'HyperV',
            SUBSYSTEM => 'MS HyperV',
            NAME      => 'vm1',
            STATUS    => STATUS_RUNNING,
            UUID      => undef,
            VCPU      => 4,
            MEMORY    => 4096,
            SERIAL    => 'QA-SN-0003',
            NETWORKS  => [
                { DESCRIPTION => 'Network Adapter', MACADDR => '00:11:22:AA:BB:03' },
            ],
            DRIVES  => [
                { VOLUMN => 'C:\HyperV\vm1.vhdx',            TOTAL => 16384 },
                { VOLUMN => 'C:\HyperV\pruebadediscosl.vhdx', TOTAL => 5120  },
            ],
        },
    ],
    # VM in paused state (EnabledState=9, CIM Quiesce) must map to STATUS_PAUSED
    'paused' => [
        {
            VMTYPE    => 'HyperV',
            SUBSYSTEM => 'MS HyperV',
            NAME      => 'VM-Testing',
            STATUS    => STATUS_PAUSED,
            UUID      => undef,
            VCPU      => 2,
            MEMORY    => 1024,
            SERIAL    => 'PAUSED-SN-0004',
            NETWORKS  => [
                { DESCRIPTION => 'Network Adapter', MACADDR => '00:11:22:AA:BB:04' },
            ],
            DRIVES    => [
                { VOLUMN => 'C:\ClusterStorage\Volume1\VM\VM-Testing\Virtual Hard Disks\VM-Testing.vhdx', TOTAL => 51200 },
            ],
        },
    ],
    # Veeam File-Level Restore appliance: has a .vfd floppy disk that must be
    # skipped (Get-VHD does not support .vfd), plus a .avhdx checkpoint disk.
    'veeam-flr' => [
        {
            VMTYPE    => 'HyperV',
            SUBSYSTEM => 'MS HyperV',
            NAME      => 'VeeamFLR_SG73COMP1_85f38199',
            STATUS    => STATUS_RUNNING,
            UUID      => undef,
            VCPU      => 2,
            MEMORY    => 2048,
            SERIAL    => 'VEEAM-SN-0005',
            NETWORKS  => [
                { DESCRIPTION => 'Network Adapter', MACADDR => '00:11:22:AA:BB:05' },
            ],
            DRIVES    => [
                { VOLUMN => 'C:\VeeamFLR\5k4y4gms.4n3\disk0_C.avhdx', TOTAL => 102400 },
            ],
            IPADDRESS => '10.95.162.58',
        },
    ],

);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new(glpi => '12');

my %vhd_sizes = (
    'C:\VMs\vm-disco.vhdx'                                                           => 107374182400,   # 102400 MB
    '\\\\nas01\VMs\vm-datos.vhdx'                                                     => 536870912000,   # 512000 MB
    'C:\HyperV\vm2.vhdx'                                                             =>  12884901888,   #  12288 MB
    'C:\HyperV\vm1.vhdx'                                                             =>  17179869184,   #  16384 MB
    'C:\HyperV\pruebadediscosl.vhdx'                                                 =>   5368709120,   #   5120 MB
    'C:\VeeamFLR\5k4y4gms.4n3\disk0_C.avhdx'                                        => 107374182400,   # 102400 MB
    'C:\ClusterStorage\Volume1\VM\VM-Testing\Virtual Hard Disks\VM-Testing.vhdx'     =>  53687091200,   #  51200 MB
    '\\\\nas02\C$\VMs\vm-admin.vhdx'                                                =>  21474836480,   #  20480 MB
);

# fake Tools::Win32, instead of Task::Inventory::Virtualization::HyperV, as
# it is loaded at runtime
my $module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);

foreach my $test (keys %tests) {
    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );
    $module->mock('runPowerShell', sub {
        my (%params) = @_;
        my ($path) = $params{script} =~ /'([^']+)'/;
        $path =~ s/''/'/g if $path;   # unescape PS single-quoted '' → '
        return $vhd_sizes{$path} // 0;
    });

    my @machines = GLPI::Agent::Task::Inventory::Virtualization::HyperV::_getVirtualMachines(inventory => $inventory);
    cmp_deeply(
        \@machines,
        $tests{$test},
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'VIRTUALMACHINES', entry => $_)
            foreach @machines;
    } "$test: registering";
}
