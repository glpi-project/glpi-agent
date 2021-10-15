#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::MacOS::Networks;

my %tests = (
    'macosx-01' => [
        {
            DESCRIPTION => 'lo0',
            IPADDRESS   => '127.0.0.1',
            IPADDRESS6  => 'fe80::1',
            IPMASK      => '255.0.0.0',
            IPSUBNET    => '127.0.0.0',
            MTU         => 16384,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'gif0',
            MTU         => 1280,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'stf0',
            MTU         => 1280,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'XHC20',
            MTU         => 0,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Ethernet',
            IPADDRESS   => '172.77.220.189',
            IPADDRESS6  => 'fe80::10f6:f9c8:4818:4587',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '172.77.220.0',
            MACADDR     => '0c:4d:e9:c9:6c:3c',
            MTU         => 1500,
            SPEED       => 100,
            STATUS      => 'Up',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Wi-Fi',
            MACADDR     => '88:63:df:b1:e6:cb',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'p2p0',
            MACADDR     => '0a:63:df:b1:e6:cb',
            MTU         => 2304,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'awdl0',
            IPADDRESS6  => 'fe80::e8c8:6eff:fec2:4f22',
            MACADDR     => 'ea:c8:6e:c2:4f:22',
            MTU         => 1484,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Thunderbolt 1',
            MACADDR     => '32:00:1e:77:00:00',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 2',
            MACADDR     => '32:00:1e:77:00:01',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt Bridge',
            MACADDR     => '32:00:1e:77:00:00',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'utun0',
            IPADDRESS6  => 'fe80::844f:4fae:3826:4704',
            MTU         => 2000,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        }
    ],
);

plan tests => (scalar keys %tests)*2 + 1;

foreach my $test (keys %tests) {
    my $ifconfig_file = "resources/macos/ifconfig/$test";
    my $netsetup_file = "resources/macos/ifconfig/$test-networksetup";

    my $netsetup;
    $netsetup = GLPI::Agent::Task::Inventory::MacOS::Networks::_parseNetworkSetup(
        file => $netsetup_file
    );
    ok( $netsetup, "_parseNetworkSetup() for $test" );

    my $nets = GLPI::Agent::Task::Inventory::MacOS::Networks::_getInterfaces(
        file        => $ifconfig_file,
        netsetup    => $netsetup
    );
    cmp_deeply($nets, $tests{$test}, $test);
}
