#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

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
            TYPE        => 'loopback',
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
            TYPE        => 'ethernet',
            MTU         => 1500,
            SPEED       => 100,
            STATUS      => 'Up',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Wi-Fi',
            MACADDR     => '88:63:df:b1:e6:cb',
            TYPE        => 'wifi',
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
            TYPE        => 'ethernet',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 2',
            MACADDR     => '32:00:1e:77:00:01',
            TYPE        => 'ethernet',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt Bridge',
            MACADDR     => '32:00:1e:77:00:00',
            TYPE        => 'bridge',
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
    'macbook-m1-pro-2021-macosx-14.5' => [
        {
            DESCRIPTION => 'lo0',
            IPADDRESS   => '127.0.0.1',
            IPADDRESS6  => 'fe80::1',
            IPMASK      => '255.0.0.0',
            IPSUBNET    => '127.0.0.0',
            MTU         => 16384,
            STATUS      => 'Down',
            TYPE        => 'loopback',
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
            DESCRIPTION => 'anpi2',
            MACADDR     => 'AA:AA:AA:AA:AA:AA',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'anpi1',
            MACADDR     => 'AA:AA:AA:AA:AA:AB',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'anpi0',
            MACADDR     => 'AA:AA:AA:AA:AA:AC',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Ethernet Adapter (en5)',
            MACADDR     => 'AA:AA:AA:AA:AA:AD',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Ethernet Adapter (en6)',
            MACADDR     => 'AA:AA:AA:AA:AA:BA',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Ethernet Adapter (en7)',
            MACADDR     => 'AA:AA:AA:AA:AA:BB',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 1',
            MACADDR     => 'AA:AA:AA:AA:AA:BC',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 2',
            MACADDR     => 'AA:AA:AA:AA:AA:BD',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 3',
            MACADDR     => 'AA:AA:AA:AA:AA:CA',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'ap1',
            IPADDRESS6  => 'fe80::a:b:c:d',
            MACADDR     => 'AA:AA:AA:AA:AA:CB',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Wi-Fi',
            IPADDRESS6  => 'fe80::b:c:d:a',
            IPMASK      => '255.255.254.0',
            MACADDR     => 'AA:AA:AA:AA:AA:CC',
            MTU         => 1500,
            STATUS      => 'Up',
            TYPE        => 'wifi',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt Bridge',
            MACADDR     => 'AA:AA:AA:AA:AA:BC',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'bridge',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'awdl0',
            IPADDRESS6  => 'fe80::a1:b1:c1:d2',
            MACADDR     => 'AA:AA:AA:AA:AA:CD',
            MTU         => 1500,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'llw0',
            IPADDRESS6  => 'fe80::a2:b2:c2:d2',
            MACADDR     => 'AA:AA:AA:AA:AA:CD',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun0',
            IPADDRESS6  => 'fe80::a3:b3:c3:d4',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun1',
            IPADDRESS6  => 'fe80::a4:b4:c4:d4',
            MTU         => 1380,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun2',
            IPADDRESS6  => 'fe80::a5:b5:c5:d5',
            MTU         => 2000,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun3',
            IPADDRESS6  => 'fe80::a6:b6:c6:d6',
            MTU         => 1000,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'ThinkPad Lan',
            MACADDR     => 'AA:AA:AA:AA:AA:DA',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 0
        }
    ],
    'macbook-pro-16-intel-2019-catalina' => [
        {
            DESCRIPTION => 'lo0',
            IPADDRESS   => '127.0.0.1',
            IPADDRESS6  => 'fe80::1',
            IPMASK      => '255.0.0.0',
            IPSUBNET    => '127.0.0.0',
            MTU         => 16384,
            STATUS      => 'Down',
            TYPE        => 'loopback',
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
            DESCRIPTION => 'en5',
            IPADDRESS6  => 'fe80::0000:00ff:ffff:0000',
            MACADDR     => 'ac:00:48:00:11:00',
            MTU         => 1500,
            SPEED       => 100,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Thunderbolt 3',
            MACADDR     => '82:00:1c:a5:00:00',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 4',
            MACADDR     => '82:00:1c:a5:00:01',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 1',
            MACADDR     => '82:00:1c:a5:00:02',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 2',
            MACADDR     => '82:00:1c:a5:00:03',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'ap1',
            MACADDR     => '56:00:ec:9f:00:02',
            MTU         => 1500,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Wi-Fi',
            MACADDR     => 'f8:00:c2:05:00:01',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'wifi',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'p2p0',
            MACADDR     => '0a:00:c2:05:00:03',
            MTU         => 2304,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'awdl0',
            MACADDR     => '92:00:06:db:00:01',
            MTU         => 1484,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'llw0',
            MACADDR     => '92:00:06:db:00:02',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Thunderbolt Bridge',
            MACADDR     => '82:00:1c:a5:00:03',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'bridge',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'utun0',
            IPADDRESS6  => 'fe80::0000:ffff:1111:0000',
            MTU         => 1380,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'vnic0',
            IPADDRESS   => '10.211.55.2',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '10.211.55.0',
            MACADDR     => '00:00:99:00:00:01',
            MTU         => 1500,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'vnic1',
            IPADDRESS   => '10.37.129.2',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '10.37.129.0',
            MACADDR     => '00:00:99:00:00:02',
            MTU         => 1500,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun1',
            IPADDRESS6  => 'fe80::0000:ffff:1111:0000',
            MTU         => 2000,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun2',
            IPADDRESS6  => 'fe80::0000:ffff:1111:0001',
            MTU         => 1380,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun3',
            IPADDRESS6  => 'fe80::0000:ffff:2222:0002',
            MTU         => 1380,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'iPhone USB',
            MACADDR     => 'd6:00:da:5b:00:05',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'dialup',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'en40',
            IPADDRESS   => '169.254.176.43',
            IPADDRESS6  => 'fe80::0000:ffff:1111:0000',
            IPMASK      => '255.255.0.0',
            IPSUBNET    => '169.254.0.0',
            MACADDR     => 'd6:00:da:5b:00:06',
            MTU         => 1500,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'en41',
            IPADDRESS   => '169.254.231.178',
            IPADDRESS6  => 'fe80::0000:ffff:1111:0004',
            IPMASK      => '255.255.0.0',
            IPSUBNET    => '169.254.0.0',
            MACADDR     => 'f2:00:4a:fa:00:06',
            MTU         => 1500,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'USB 10/100/1000 LAN',
            IPADDRESS   => '192.168.0.205',
            IPADDRESS6  => 'fe80::0000:ffff:0000:0003',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '192.168.0.0',
            MACADDR     => '98:00:43:0f:00:03',
            MTU         => 1500,
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'bridge100',
            IPADDRESS   => '192.168.2.1',
            IPADDRESS6  => 'fe80::0000:ffff:0000:0001',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '192.168.2.0',
            MACADDR     => 'fa:00:c2:50:00:02',
            MTU         => 1500,
            STATUS      => 'Up',
            TYPE        => 'bridge',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun4',
            IPADDRESS   => '10.75.129.190',
            IPADDRESS6  => 'fe80::1111:2222:eeee:0000',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '10.75.129.0',
            MTU         => 1390,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        }
    ],
    'macbook-pro-16-apple-silicon-2021-macosx-14.4' => [
        {
            DESCRIPTION => 'lo0',
            IPADDRESS   => '127.0.0.1',
            IPADDRESS6  => 'fe80::1',
            IPMASK      => '255.0.0.0',
            IPSUBNET    => '127.0.0.0',
            MTU         => 16384,
            STATUS      => 'Down',
            TYPE        => 'loopback',
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
            DESCRIPTION => 'anpi1',
            MACADDR     => '9e:00:06:96:00:0c',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'anpi0',
            MACADDR     => '9e:00:06:96:00:0b',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Ethernet Adapter (en4)',
            MACADDR     => '9e:00:06:96:00:70',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Ethernet Adapter (en5)',
            MACADDR     => '9e:00:06:96:00:71',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 1',
            MACADDR     => '36:00:07:a1:00:00',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 2',
            MACADDR     => '36:00:07:a1:00:04',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 3',
            MACADDR     => '36:00:07:a1:00:08',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt Bridge',
            MACADDR     => '36:00:07:a1:00:00',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'bridge',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'ap1',
            IPADDRESS6  => 'fe80::0000:5555:7777:4444',
            MACADDR     => '62:00:0f:57:00:44',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Wi-Fi',
            IPADDRESS   => '192.168.2.46',
            IPADDRESS6  => 'fe80::4444:3333:0000:5555',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '192.168.2.0',
            MACADDR     => '60:00:50:57:00:44',
            MTU         => 1500,
            STATUS      => 'Up',
            TYPE        => 'wifi',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'awdl0',
            IPADDRESS6  => 'fe80::8888:ffff:2222:aeae',
            MACADDR     => '1a:00:08:c2:00:80',
            MTU         => 1500,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'llw0',
            IPADDRESS6  => 'fe80::8888:ffff:2222:aeae',
            MACADDR     => '1a:00:08:c2:00:80',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun0',
            IPADDRESS6  => 'fe80::6666:3333:2121:1010',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun1',
            IPADDRESS6  => 'fe80::3434:dada:0000:0000',
            MTU         => 1380,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun2',
            IPADDRESS6  => 'fe80::cdcd:0000:8888:6666',
            MTU         => 2000,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun3',
            IPADDRESS6  => 'fe80::cece:bbbb:cccc:0000',
            MTU         => 1000,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        }
    ],
    'imac-27-intel-2019-macosx-10.14.6' => [
        {
            DESCRIPTION => 'lo0',
            IPADDRESS   => '127.0.0.1',
            IPADDRESS6  => 'fe80::1',
            IPMASK      => '255.0.0.0',
            IPSUBNET    => '127.0.0.0',
            MTU         => 16384,
            STATUS      => 'Down',
            TYPE        => 'loopback',
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
            DESCRIPTION => 'XHC0',
            MTU         => 0,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Ethernet',
            IPADDRESS   => '10.71.127.11',
            IPADDRESS6  => 'fe80::8844:fade:b431:000a',
            IPMASK      => '255.255.224.0',
            IPSUBNET    => '10.71.96.0',
            MACADDR     => '3c:36:00:60:88:11',
            MTU         => 1500,
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 1',
            MACADDR     => 'aa:00:44:c1:dd:e0',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt 2',
            MACADDR     => 'aa:00:44:c1:dd:e1',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'Thunderbolt Bridge',
            MACADDR     => 'aa:00:44:c1:dd:e0',
            MTU         => 1500,
            STATUS      => 'Down',
            TYPE        => 'bridge',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'ap1',
            MACADDR     => 'fa:cc:f2:56:77:6b',
            MTU         => 1500,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'Wi-Fi',
            IPADDRESS   => '192.168.1.107',
            IPADDRESS6  => 'fe80::1000:6100:00ea:0000',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '192.168.1.0',
            MACADDR     => 'f8:cc:f2:56:77:6b',
            MTU         => 1500,
            STATUS      => 'Up',
            TYPE        => 'wifi',
            VIRTUALDEV  => 0
        },
        {
            DESCRIPTION => 'p2p0',
            MACADDR     => '0a:cc:f2:56:77:6b',
            MTU         => 2304,
            STATUS      => 'Down',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'awdl0',
            IPADDRESS6  => 'fe80::8484:00ff:fe00:00ca',
            MACADDR     => '86:33:72:94:77:aa',
            MTU         => 1484,
            STATUS      => 'Up',
            VIRTUALDEV  => 1
        },
        {
            DESCRIPTION => 'utun0',
            IPADDRESS6  => 'fe80::0000:5555:cd42:000a',
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
    if (ref($tests{$test}) eq 'ARRAY' && scalar(@{$tests{$test}})) {
        cmp_deeply($nets, $tests{$test}, $test);
    } else {
        my $dumper = Data::Dumper->new([$nets], [$test])->Useperl(1)->Indent(1)->Quotekeys(0)->Sortkeys(1)->Pad("    ");
        $dumper->{xpad} = "    ";
        print STDERR $dumper->Dump();
        fail "$test: still no result integrated";
    }
}
