#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use Test::MockModule;
use UNIVERSAL::require;
use Test::Deep;

use GLPI::Test::Utils;
use GLPI::Agent::Inventory;

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
          {
            'DESCRIPTION' => 'Ethernet',
            'IFINBYTES' => '1412918786473',
            'IFINERRORS' => '0',
            'IFOUTBYTES' => '364462371847',
            'IFOUTERRORS' => '0',
            'MACADDR' => '20:47:47:90:78:42',
            'MANUFACTURER' => 'Microsoft',
            'MODEL' => 'Broadcom NetXtreme Gigabit Ethernet',
            'PCIID' => '14E4:165F:05E5:1028',
            'PNPDEVICEID' => 'PCI\\VEN_14E4&DEV_165F&SUBSYS_05E51028&REV_00\\000020474790784200',
            'SPEED' => 1000,
            'STATUS' => 'Up',
            'TYPE' => 'ethernet',
            'VIRTUALDEV' => 0
          },
          {
            'DESCRIPTION' => 'Ethernet 2',
            'IFINBYTES' => '70987676',
            'IFINERRORS' => '0',
            'IFOUTBYTES' => '80987676',
            'IFOUTERRORS' => '0',
            'MACADDR' => '20:47:47:90:78:44',
            'MANUFACTURER' => 'Microsoft',
            'MODEL' => 'Broadcom NetXtreme Gigabit Ethernet',
            'PCIID' => '14E4:165F:05E5:1028',
            'PNPDEVICEID' => 'PCI\\VEN_14E4&DEV_165F&SUBSYS_05E51028&REV_00\\000020474790784401',
            'SPEED' => 1000,
            'STATUS' => 'Up',
            'TYPE' => 'ethernet',
            'VIRTUALDEV' => 0
          },
          {
            'DESCRIPTION' => 'LoadBalance',
            'IFINBYTES' => '1403973923755',
            'IFINERRORS' => '0',
            'IFOUTBYTES' => '726370059830',
            'IFOUTERRORS' => '0',
            'IPADDRESS' => '192.168.10.250',
            'IPDHCP' => undef,
            'IPGATEWAY' => '192.168.10.254',
            'IPMASK' => '255.255.255.0',
            'IPSUBNET' => '192.168.10.0',
            'MACADDR' => '20:47:47:90:78:42',
            'MANUFACTURER' => 'Microsoft',
            'MODEL' => 'Microsoft Network Adapter Multiplexor Driver',
            'PNPDEVICEID' => 'COMPOSITEBUS\\MS_IMPLAT_MP\\{1280DFA8-1A33-437E-88B0-238F0C879599}',
            'SPEED' => 2000,
            'STATUS' => 'Up',
            'TYPE' => 'ethernet',
            'VIRTUALDEV' => 1
          }
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

    my @ports = GLPI::Agent::Task::Inventory::Win32::Networks::_getInterfaces(
        glpi12_support => 1
    );

    # The returned ports contain dns and GUID which are cleaned up by doInventory.
    # We clean them up here before cmp_deeply and addEntry.
    foreach my $port (@ports) {
        delete $port->{dns};
        delete $port->{DNSDomain};
        delete $port->{GUID};
    }

    cmp_deeply(
        \@ports,
        $network_ports_tests{$test},
        "$test sample NETWORKS matches expected counters"
    );

    # Prove we don't break expected inventory format
    my $inventory = GLPI::Agent::Inventory->new(glpi => '12.0.0');
    eval {
        foreach my $port (@ports) {
            $inventory->addEntry(
                section => 'NETWORKS',
                entry   => $port
            );
        }
    };
    is($EVAL_ERROR, '', "addEntry does not throw exceptions for $test ports");
}
