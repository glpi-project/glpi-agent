#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use Test::MockModule;
use UNIVERSAL::require;
use Test::Deep qw(cmp_deeply bag);

use GLPI::Test::Utils;

BEGIN {
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

Test::NoWarnings->use();

GLPI::Agent::Task::Inventory::Win32::Networks->require();

package MockInventory;
sub new { bless { sections => {} }, shift }
sub addEntry {
    my ($self, %params) = @_;
    push @{$self->{sections}->{$params{section}}}, $params{entry};
}
sub setHardware { }

package main;

my %tests = (
    'loadbalance' => [
        {
            mac => '20:47:47:90:78:42',
            name => 'LoadBalance',
            ifinoctets => 1403973923755,
            ifoutoctets => 726370059830,
            ifinerrors => 0,
            ifouterrors => 0
        }
    ],
    '7' => [
        {
            mac => 'F4:6D:04:97:2D:3E',
            name => 'Connexion au réseau local',
            ifinoctets => 1403627350071,
            ifoutoctets => 364462371847,
            ifinerrors => 0,
            ifouterrors => 0
        }
    ]
);

plan tests => scalar(keys %tests) * 2 + 1;


my $win32_module = Test::MockModule->new('GLPI::Agent::Tools::Win32');
my $net_module = Test::MockModule->new('GLPI::Agent::Task::Inventory::Win32::Networks');


# Mock getRegistryKey to just return nothing, so getInterfaces skips vpn enumeration
$win32_module->mock(
    'getRegistryKey',
    sub { return {}; }
);

foreach my $test (keys %tests) {
    
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
    
    ok(exists $inventory->{sections}->{NETWORKPORTS}, "$test generates NETWORKPORTS");
    
    my $ports = $inventory->{sections}->{NETWORKPORTS} || [];
    
    
    cmp_deeply(
        $ports,
        bag(@{$tests{$test}}),
        "$test sample NETWORKPORTS matches expected counters"
    );
}

