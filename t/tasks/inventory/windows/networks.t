#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use Test::MockModule;
use UNIVERSAL::require;
use Test::Deep qw(cmp_deeply superbagof superhashof);

use GLPI::Test::Utils;

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

GLPI::Agent::Task::Inventory::Win32::Networks->require();

package MockInventory;
sub new { bless { sections => {}, _glpi_version => 12_000_000 }, shift }
sub supportsGlpiVersion { 1 }
sub addEntry {
    my ($self, %params) = @_;
    push @{$self->{sections}->{$params{section}}}, $params{entry};
}
sub setHardware { }

package main;

my %tests = (
    xp => {
        'PCI\VEN_1022&DEV_2000&SUBSYS_20001022&REV_10\\4&47B7341&0&0088' => 'ethernet',
        'ROOT\\MS_PSCHEDMP\\0001' => undef,
        'ROOT\\MS_PSCHEDMP\\0002' => undef,
        'ROOT\\MS_PSCHEDMP\\0003' => undef,
        'ROOT\\MS_PPTPMINIPORT\\0000' => undef,
        'ROOT\\MS_PPPOEMINIPORT\\0000' => undef
    },
);

my %network_ports_tests = (
    'loadbalance' => [
        superhashof({
            MACADDR => '20:47:47:90:78:42',
            DESCRIPTION => 'Broadcom NetXtreme Gigabit Ethernet',
            IFINBYTES => 1412918786473,
            IFOUTBYTES => 364462371847,
            IFINERRORS => 0,
            IFOUTERRORS => 0
        }),
        superhashof({
            MACADDR => '20:47:47:90:78:44',
            DESCRIPTION => 'Broadcom NetXtreme Gigabit Ethernet',
            IFINBYTES => 70987676,
            IFOUTBYTES => 80987676,
            IFINERRORS => 0,
            IFOUTERRORS => 0
        }),
        superhashof({
            MACADDR => '20:47:47:90:78:42',
            DESCRIPTION => 'Microsoft Network Adapter Multiplexor Driver',
            IFINBYTES => 1403973923755,
            IFOUTBYTES => 726370059830,
            IFINERRORS => 0,
            IFOUTERRORS => 0
        })
    ]
);

my $plan = 1;
foreach my $test (keys %tests) {
    $plan += scalar (keys %{$tests{$test}});
}
$plan += scalar(keys %network_ports_tests) * 2;
plan tests => $plan;

foreach my $test (keys %tests) {

    my $file = "resources/win32/registry/$test-{4D36E972-E325-11CE-BFC1-08002BE10318}.reg";
    my $keys = loadRegistryDump($file);

    foreach my $deviceId (keys %{$tests{$test}}) {
        is(
            GLPI::Agent::Task::Inventory::Win32::Networks::_getMediaType($deviceId, $keys),
            $tests{$test}->{$deviceId},
            "$test sample, $deviceId device"
        );
    }
}

my $win32_module = Test::MockModule->new('GLPI::Agent::Tools::Win32');
my $net_module = Test::MockModule->new('GLPI::Agent::Task::Inventory::Win32::Networks');

# Mock getRegistryKey to just return nothing, so getInterfaces skips vpn enumeration
$win32_module->mock(
    'getRegistryKey',
    sub { return {}; }
);

foreach my $test (keys %network_ports_tests) {

    $win32_module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );
    $net_module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );
    $net_module->mock(
        'getRegistryKey',
        sub { return {}; }
    );

    my $inventory = MockInventory->new();

    GLPI::Agent::Task::Inventory::Win32::Networks::doInventory(
        inventory => $inventory,
    );

    ok(exists $inventory->{sections}->{NETWORKS}, "$test generates NETWORKS");

    my $ports = $inventory->{sections}->{NETWORKS} || [];

    cmp_deeply(
        $ports,
        superbagof(@{$network_ports_tests{$test}}),
        "$test sample NETWORKS matches expected counters"
    );
}
