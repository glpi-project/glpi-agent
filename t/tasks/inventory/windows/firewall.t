#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use Test::Deep;
use Test::MockModule;
use UNIVERSAL::require;
use GLPI::Test::Utils;
use GLPI::Agent::Tools::Constants;

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
GLPI::Agent::Task::Inventory::Win32::Firewall->require();

my %expectedFirewallProfiles = (
    '7_firewall' => {
        domain   => {
            STATUS  => STATUS_OFF,
            PROFILE => 'DomainProfile'
        },
        public   => {
            STATUS  => STATUS_OFF,
            PROFILE => 'PublicProfile'
        },
        standard => {
            STATUS  => STATUS_OFF,
            PROFILE => 'StandardProfile'
        }
    },
    '10' => {
        domain   => {
            STATUS  => STATUS_ON,
            PROFILE => 'DomainProfile'
        },
        public   => {
            STATUS  => STATUS_ON,
            PROFILE => 'PublicProfile'
        },
        standard => {
            STATUS  => STATUS_ON,
            PROFILE => 'StandardProfile'
        }
    }
);

my %expectedProfilesForInventory = (
    '7_firewall' => [
        {
            STATUS  => STATUS_OFF,
            PROFILE => 'DomainProfile',
            DESCRIPTION => 'Carte Intel(R) PRO/1000 MT pour station de travail',
            IPADDRESS => '0.0.0.1'
        },
        {
            STATUS  => STATUS_OFF,
            PROFILE => 'DomainProfile',
            DESCRIPTION => 'Carte Intel(R) PRO/1000 MT pour station de travail',
            IPADDRESS6 => 'fe81::fe81:fe81:fe81:fe81'
        },
        {
            STATUS  => STATUS_OFF,
            PROFILE => 'PublicProfile'
        },
        {
            STATUS  => STATUS_OFF,
            PROFILE => 'StandardProfile'
        }
    ],
    '10' => [
        {
            STATUS  => STATUS_ON,
            PROFILE => 'DomainProfile'
        },
        {
            STATUS  => STATUS_ON,
            PROFILE => 'PublicProfile'
        },
        {
            STATUS  => STATUS_ON,
            PROFILE => 'StandardProfile',
            DESCRIPTION => 'Intel(R) PRO/1000 MT Desktop Adapter',
            IPADDRESS => '0.0.0.9'
        },
        {
            STATUS  => STATUS_ON,
            PROFILE => 'StandardProfile',
            DESCRIPTION => 'Intel(R) PRO/1000 MT Desktop Adapter',
            IPADDRESS6 => 'fe82::fe82:fe82:fe82:fe82'
        }
    ]
);

plan tests => 1
        + scalar (keys %expectedFirewallProfiles)
        + scalar (keys %expectedProfilesForInventory);

my $module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);

for my $testKey (keys %expectedFirewallProfiles) {

    $module->mock(
        '_getRegistryKey',
        _mockGetRegistryKey($testKey)
    );

    my $firewallProfiles = GLPI::Agent::Task::Inventory::Win32::Firewall::_getFirewallProfiles();
    cmp_deeply (
        $firewallProfiles,
        $expectedFirewallProfiles{$testKey},
        'test windows ' . $testKey . ' FirewallPolicy: extract firewall profiles from registry'
    );

    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($testKey)
    );

    my @profiles =  GLPI::Agent::Task::Inventory::Win32::Firewall::_makeProfileAndConnectionsAssociation();

    # we must sort values before compare it
    my $sortingSub = sub {
        my $list = shift;
        return sort {
            $a->{PROFILE} cmp $b->{PROFILE} ||
            ($a->{IPADDRESS} || $a->{IPADDRESS6} || "") cmp ($b->{IPADDRESS} || $b->{IPADDRESS6} || "")
        } @$list;
    };
    @profiles = &$sortingSub(\@profiles);
    my @expectedProfiles = &$sortingSub($expectedProfilesForInventory{$testKey});
    cmp_deeply (
        \@profiles,
        \@expectedProfiles,
        'test windows ' . $testKey . ' _getFirewallProfiles()'
    );
}

# Adapted from GLPI::Test::Utils mockGetRegistryKey() to support
# shared subkey from NetworkList registry dumps
sub _mockGetRegistryKey {
    my ($test) = @_;

    return sub {
        my (%params) = @_;

        # We can mock getRegistryKey or better _getRegistryKey to cover getRegistryValue
        my $path = $params{path} || $params{keyName};
        my $last_elt = (split(/\//, $path))[-1];
        my $file = "resources/win32/registry/";
        if ($last_elt eq 'Profiles' || $last_elt eq 'Signatures') {;
            $file .= "$test-NetworkList.reg";
            return loadRegistryDump($file)->{$last_elt.'/'};
        } else {
            $file .= "$test-$last_elt.reg";
            return loadRegistryDump($file);
        }
    };
}
