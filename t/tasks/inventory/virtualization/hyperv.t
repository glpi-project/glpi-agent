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
            DRIVES  => [],
        },
        {
            VMTYPE    => 'HyperV',
            SUBSYSTEM => 'MS HyperV',
            NAME      => 'COLETA_FABIANO',
            STATUS    => STATUS_RUNNING,
            UUID      => undef,
            VCPU      => undef,
            MEMORY    => undef,
            DRIVES  => [],
        },
        {
            SUBSYSTEM => 'MS HyperV',
            VMTYPE    => 'HyperV',
            NAME      => 'W2012',
            STATUS    => STATUS_OFF,
            UUID      => undef,
            VCPU      => undef,
            MEMORY    => undef,
            DRIVES  => [],
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
            DRIVES  => [
                { VOLUMN => 'C:\VMs\vm-disco.vhdx',        TOTAL => 102400 },
                { VOLUMN => '\\\\nas01\VMs\vm-datos.vhdx',  TOTAL => 512000 },
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
            DRIVES  => [
                { VOLUMN => 'C:\HyperV\vm1.vhdx',            TOTAL => 16384 },
                { VOLUMN => 'C:\HyperV\pruebadediscosl.vhdx', TOTAL => 5120  },
            ],
        },
    ],

);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new(glpi => '10.0.25');

my %vhd_sizes = (
    'C:\VMs\vm-disco.vhdx'                => 107374182400,   # 102400 MB
    '\\\\nas01\VMs\vm-datos.vhdx'          => 536870912000,   # 512000 MB
    'C:\HyperV\vm2.vhdx'                  =>  12884901888,   #  12288 MB
    'C:\HyperV\vm1.vhdx'                  =>  17179869184,   #  16384 MB
    'C:\HyperV\pruebadediscosl.vhdx'      =>   5368709120,   #   5120 MB
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
        my ($path) = $params{script} =~ /"([^"]+)"/;
        return $vhd_sizes{$path} // 0;
    });

    my @machines = GLPI::Agent::Task::Inventory::Virtualization::HyperV::_getVirtualMachines($inventory);
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
