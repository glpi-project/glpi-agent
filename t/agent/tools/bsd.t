#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;

use GLPI::Agent::Tools::BSD;

my %ifconfig_tests = (
    'freebsd-8.1' => [
        {
            DESCRIPTION => 're0',
            MACADDR     => 'c8:0a:a9:3f:35:fa',
            STATUS      => 'Up',
            MTU         => '1500',
            TYPE        => 'ethernet',
            IPADDRESS   => '129.132.95.98',
            IPSUBNET    => '129.132.95.64',
            IPMASK      => '255.255.255.192',
        },
        {
            DESCRIPTION => 'fwe0',
            MACADDR     => '02:24:1b:9d:ca:01',
            STATUS      => 'Down',
            MTU         => '1500',
        },
        {
            DESCRIPTION => 'fwip0',
            STATUS      => 'Down',
            MTU         => '1500',
        },
        {
            DESCRIPTION => 'lo0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS6  => 'fe80::1',
            IPSUBNET6   => 'fe80::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
        },
        {
            DESCRIPTION => 'lo0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS6  => '::1',
            IPSUBNET6   => '::1',
            IPMASK6     => 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
        },
        {
            DESCRIPTION => 'lo0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS   => '127.0.0.1',
            IPSUBNET    => '127.0.0.0',
            IPMASK      => '255.0.0.0',
        },
        {
            DESCRIPTION => 'vboxnet0',
            MACADDR     => '0a:00:27:00:00:00',
            STATUS      => 'Down',
            MTU         => '1500',
        },
        {
            DESCRIPTION => 'tun0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '1500',
            IPADDRESS   => '192.168.200.6',
            IPSUBNET    => '192.168.200.6',
            IPMASK      => '255.255.255.255',
        }
    ],
    'freebsd-bis' => [
        {
            DESCRIPTION => 'bce0',
            MACADDR     => '00:16:18:87:ca:b5',
            STATUS      => 'Up',
            MTU         => '1500',
            TYPE        => 'ethernet',
            IPADDRESS   => '11.105.11.105',
            IPSUBNET    => '11.105.11.64',
            IPMASK      => '255.255.255.192',

        },
        {
            DESCRIPTION => 'bce0',
            MACADDR     => '00:16:18:87:ca:b5',
            STATUS      => 'Up',
            MTU         => '1500',
            TYPE        => 'ethernet',
            IPADDRESS   => '11.105.11.110',
            IPSUBNET    => '11.105.11.110',
            IPMASK      => '255.255.255.255',

        },
        {
            DESCRIPTION => 'bce0',
            MACADDR     => '00:16:18:87:ca:b5',
            STATUS      => 'Up',
            MTU         => '1500',
            TYPE        => 'ethernet',
            IPADDRESS   => '11.105.11.111',
            IPSUBNET    => '11.105.11.111',
            IPMASK      => '255.255.255.255',
        },
        {
            DESCRIPTION => 'bce1',
            MACADDR     => '00:16:18:87:ca:b6',
            STATUS      => 'Up',
            MTU         => '1500',
            TYPE        => 'ethernet',
            IPADDRESS   => '192.168.12.105',
            IPSUBNET    => '192.168.12.0',
            IPMASK      => '255.255.255.0',

        },
        {
            DESCRIPTION => 'lo0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS6  => 'fe80::1',
            IPSUBNET6   => 'fe80::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',

        },
        {
            DESCRIPTION => 'lo0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS6  => '::1',
            IPSUBNET6   => '::1',
            IPMASK6     => 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
        },
        {
            DESCRIPTION => 'lo0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS   => '127.0.0.1',
            IPSUBNET    => '127.0.0.0',
            IPMASK      => '255.0.0.0',

        }
    ],
    'freebsd-ter' => [
        {
            DESCRIPTION => 'em0',
            MACADDR     => '00:23:18:cf:0d:93',
            STATUS      => 'Up',
            MTU         => '1500',
            TYPE        => 'ethernet'
        },
        {
            DESCRIPTION => 'lo0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS6  => '::1',
            IPSUBNET6   => '::1',
            IPMASK6     => 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
        },
        {
            DESCRIPTION => 'lo0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS6  => 'fe80::1',
            IPSUBNET6   => 'fe80::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
        },
        {
            DESCRIPTION => 'lo0',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS   => '127.0.0.1',
            IPSUBNET    => '127.0.0.0',
            IPMASK      => '255.0.0.0',
        },
        {
            DESCRIPTION => 'lo1',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS   => '10.0.0.254',
            IPSUBNET    => '10.0.0.0',
            IPMASK      => '255.255.255.0',
        },
        {
            DESCRIPTION => 'lo1',
            MACADDR     => undef,
            STATUS      => 'Up',
            MTU         => '16384',
            IPADDRESS   => '10.0.0.1',
            IPSUBNET    => '10.0.0.0',
            IPMASK      => '255.255.255.0',
        },
        {
            DESCRIPTION => 'ndis0',
            MACADDR     => '4c:ed:de:2c:9d:9a',
            STATUS      => 'Up',
            MTU         => '2290',
            TYPE        => 'wifi'
        },
        {
            DESCRIPTION  => 'wlan0',
            MACADDR      => '4c:ed:de:2c:9d:9a',
            STATUS       => 'Up',
            MTU          => '1500',
            TYPE         => 'wifi',
            IPADDRESS    => '192.168.0.158',
            IPSUBNET     => '192.168.0.0',
            IPMASK       => '255.255.255.0',
            WIFI_SSID    => 'BZH',
            WIFI_BSSID   => '00:07:cb:01:85:50',
            WIFI_VERSION => '802.11g',
        },
        {
            DESCRIPTION => 'vboxnet0',
            MACADDR     => '0a:00:27:00:00:00',
            STATUS      => 'Down',
            MTU         => '1500',
        }
    ],
    'freebsd-4' => [
        {
            DESCRIPTION => 'iwn0',
            MACADDR     => '3c:a9:f4:5a:04:b8',
            STATUS      => 'Up',
            TYPE        => 'wifi',
            MTU         => '2290',
        },
        {
            DESCRIPTION  => 'wlan0',
            MACADDR      => '3c:a9:f4:5a:04:b8',
            STATUS       => 'Up',
            MTU          => '1500',
            TYPE         => 'wifi',
            IPADDRESS    => '192.168.20.114',
            IPSUBNET     => '192.168.20.0',
            IPMASK       => '255.255.255.0',
            WIFI_SSID    => 'ciscosb-2',
            WIFI_BSSID   => 'c6:64:13:c5:50:c7',
            WIFI_VERSION => '802.11g',
        }
    ],
);

plan tests => scalar keys %ifconfig_tests;

foreach my $test (keys %ifconfig_tests) {
    my $file = "resources/generic/ifconfig/$test";
    my @interfaces = getInterfacesFromIfconfig(file => $file);
    cmp_deeply(\@interfaces, $ifconfig_tests{$test}, $test);
}
