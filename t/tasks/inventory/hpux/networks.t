#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::HPUX::Networks;

my %lanadmin_tests = (
    'hpux1-0' => {
        'Outbound Discards' => '0',
        'PPA Number' => '0',
        'Outbound Octets' => '1880378407',
        'Internal MAC Receive Errors' => '0',
        'Inbound Unicast Packets' => '901741518',
        'Specific' => '655367',
        'Late Collisions' => '0',
        'Outbound Queue Length' => '0',
        'Outbound Errors' => '0',
        'Alignment Errors' => '0',
        'Single Collision Frames' => '0',
        'FCS Errors' => '0',
        'Last Change' => '287',
        'Administration Status (value)' => 'up(1)',
        'Deferred Transmissions' => '0',
        'Inbound Non-Unicast Packets' => '18997',
        'Operation Status (value)' => 'up(1)',
        'Speed' => '1000000000',
        'Type (value)' => 'ethernet-csmacd(6)',
        'Carrier Sense Errors' => '0',
        'Inbound Discards' => '0',
        'Outbound Non-Unicast Packets' => '11245',
        'MTU Size' => '1500',
        'Inbound Unknown Protocols' => '235',
        'Index' => '1',
        'Excessive Collisions' => '0',
        'Multiple Collision Frames' => '0',
        'Inbound Errors' => '0',
        'Internal MAC Transmit Errors' => '0',
        'Outbound Unicast Packets' => '507550720',
        'Inbound Octets' => '3964472983',
        'Station Address' => '0x16353eac5c',
        'Description' => 'lan0 HP PCI-X 1000Base-T Release PHNE_36236 B.11.23.0706.02',
        'Frames Too Long' => '0'
    },
    'hpux1-1' => {
        'Outbound Discards' => '0',
        'PPA Number' => '1',
        'Outbound Octets' => '0',
        'Internal MAC Receive Errors' => '0',
        'Inbound Unicast Packets' => '0',
        'Specific' => '655367',
        'Late Collisions' => '0',
        'Outbound Queue Length' => '0',
        'Outbound Errors' => '0',
        'Alignment Errors' => '0',
        'Single Collision Frames' => '0',
        'FCS Errors' => '0',
        'Last Change' => '284',
        'Administration Status (value)' => 'up(1)',
        'Deferred Transmissions' => '0',
        'Inbound Non-Unicast Packets' => '30242',
        'Operation Status (value)' => 'up(1)',
        'Speed' => '1000000000',
        'Type (value)' => 'ethernet-csmacd(6)',
        'Carrier Sense Errors' => '0',
        'Inbound Discards' => '0',
        'Outbound Non-Unicast Packets' => '0',
        'MTU Size' => '1500',
        'Inbound Unknown Protocols' => '30242',
        'Index' => '2',
        'Excessive Collisions' => '0',
        'Multiple Collision Frames' => '0',
        'Inbound Errors' => '0',
        'Internal MAC Transmit Errors' => '0',
        'Outbound Unicast Packets' => '0',
        'Inbound Octets' => '2951500',
        'Station Address' => '0x16353eac5d',
        'Description' => 'lan1 HP PCI-X 1000Base-T Release PHNE_36236 B.11.23.0706.02',
        'Frames Too Long' => '0'
    },
    'hpux2-0' => {
        'Outbound Discards' => '0',
        'PPA Number' => '0',
        'Outbound Octets' => '3382475092',
        'Internal MAC Receive Errors' => '0',
        'Inbound Unicast Packets' => '1565864523',
        'Specific' => '655367',
        'Late Collisions' => '0',
        'Outbound Queue Length' => '0',
        'Outbound Errors' => '0',
        'Alignment Errors' => '0',
        'Single Collision Frames' => '0',
        'FCS Errors' => '0',
        'Last Change' => '268',
        'Administration Status (value)' => 'up(1)',
        'Deferred Transmissions' => '0',
        'Inbound Non-Unicast Packets' => '1',
        'Operation Status (value)' => 'up(1)',
        'Speed' => '1000000000',
        'Type (value)' => 'ethernet-csmacd(6)',
        'Carrier Sense Errors' => '0',
        'Inbound Discards' => '0',
        'Outbound Non-Unicast Packets' => '40950',
        'MTU Size' => '1500',
        'Inbound Unknown Protocols' => '55',
        'Index' => '1',
        'Excessive Collisions' => '0',
        'Multiple Collision Frames' => '0',
        'Inbound Errors' => '0',
        'Internal MAC Transmit Errors' => '0',
        'Outbound Unicast Packets' => '630798380',
        'Inbound Octets' => '1555284142',
        'Station Address' => '0x18fe28e080',
        'Description' => 'lan0 HP PCI-X 1000Base-T Release PHNE_36236 B.11.23.0706.02',
        'Frames Too Long' => '0'
    },
    'hpux2-1' => {
        'Outbound Discards' => '0',
        'PPA Number' => '1',
        'Outbound Octets' => '0',
        'Internal MAC Receive Errors' => '0',
        'Inbound Unicast Packets' => '0',
        'Specific' => '655367',
        'Late Collisions' => '0',
        'Outbound Queue Length' => '0',
        'Outbound Errors' => '0',
        'Alignment Errors' => '0',
        'Single Collision Frames' => '0',
        'FCS Errors' => '0',
        'Last Change' => '283',
        'Administration Status (value)' => 'up(1)',
        'Deferred Transmissions' => '0',
        'Inbound Non-Unicast Packets' => '40951',
        'Operation Status (value)' => 'up(1)',
        'Speed' => '1000000000',
        'Type (value)' => 'ethernet-csmacd(6)',
        'Carrier Sense Errors' => '0',
        'Inbound Discards' => '0',
        'Outbound Non-Unicast Packets' => '0',
        'MTU Size' => '1500',
        'Inbound Unknown Protocols' => '40951',
        'Index' => '2',
        'Excessive Collisions' => '0',
        'Multiple Collision Frames' => '0',
        'Inbound Errors' => '0',
        'Internal MAC Transmit Errors' => '0',
        'Outbound Unicast Packets' => '0',
        'Inbound Octets' => '2620864',
        'Station Address' => '0x18fe28e081',
        'Description' => 'lan1 HP PCI-X 1000Base-T Release PHNE_36236 B.11.23.0706.02',
        'Frames Too Long' => '0'
    },
);

my %ifconfig_tests = (
     'hpux1-lan0' => {
          status  => 'Up',
          netmask => '255.255.255.224',
          address => '10.0.4.56'
     },
     'hpux2-lan0' => {
          status  => 'Up',
          netmask => '255.255.255.224',
          address => '10.0.0.48'
     },
);

my %nwmgr_tests = (
    sample1 => {
        lan7 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:d0:87',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan13 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:d0:8e',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan5000 => {
            media      => 'vlan',
            status     => 'UP',
            mac        => '00:17:a4:77:04:28',
            related_if => undef,
            driver     => 'vlan'
        },
        lan1 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:04:2a',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan4 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:d0:82',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan11 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:04:48',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan0 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:04:28',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan9 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:04:2e',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan902 => {
            media      => 'hp_apa',
            status     => 'DOWN',
            mac        => '00:00:00:00:00:00',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan2 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '00:17:a4:77:04:38',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan10 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:04:46',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan903 => {
            media      => 'hp_apa',
            status     => 'DOWN',
            mac        => '00:00:00:00:00:00',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan900 => {
            media      => 'hp_apa',
            status     => 'UP',
            mac        => '00:17:a4:77:04:28',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan3 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '00:17:a4:77:04:3a',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan14 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:d0:8b',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan15 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:d0:8f',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan5001 => {
            media      => 'vlan',
            status     => 'UP',
            mac        => '00:17:a4:77:04:46',
            related_if => undef,
            driver     => 'vlan'
        },
        lan8 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:04:2c',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan6 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:d0:83',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan12 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:d0:8a',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan904 => {
            media      => 'hp_apa',
            status     => 'DOWN',
            mac        => '00:00:00:00:00:00',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan901 => {
            media      => 'hp_apa',
            status     => 'UP',
            mac        => '00:17:a4:77:04:46',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan5 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:d0:86',
            related_if => undef,
            driver     => 'iexgbe'
        }
    },
    sample2 => {
        lan7 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:73:2d',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan13 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:73:34',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan5000 => {
            media      => 'vlan',
            status     => 'UP',
            mac        => '00:17:a4:77:00:20',
            related_if => undef,
            driver     => 'vlan'
        },
        lan1 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:00:22',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan4 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:73:28',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan11 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:00:50',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan0 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:00:20',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan9 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:00:26',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan902 => {
            media      => 'hp_apa',
            status     => 'DOWN',
            mac        => '00:00:00:00:00:00',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan2 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '00:17:a4:77:00:42',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan10 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:00:40',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan903 => {
            media      => 'hp_apa',
            status     => 'DOWN',
            mac        => '00:00:00:00:00:00',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan900 => {
            media      => 'hp_apa',
            status     => 'UP',
            mac        => '00:17:a4:77:00:20',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan3 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '00:17:a4:77:00:3e',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan14 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:73:31',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan15 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:73:35',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan5001 => {
            media      => 'vlan',
            status     => 'UP',
            mac        => '00:17:a4:77:00:40',
            related_if => undef,
            driver     => 'vlan'
        },
        lan8 => {
            media      => '10GBASE',
            status     => 'UP',
            mac        => '00:17:a4:77:00:24',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan6 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:73:29',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan12 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:73:30',
            related_if => undef,
            driver     => 'iexgbe'
        },
        lan904 => {
            media      => 'hp_apa',
            status     => 'DOWN',
            mac        => '00:00:00:00:00:00',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan901 => {
            media      => 'hp_apa',
            status     => 'UP',
            mac        => '00:17:a4:77:00:40',
            related_if => undef,
            driver     => 'hp_apa'
        },
        lan5 => {
            media      => '10GBASE',
            status     => 'DOWN',
            mac        => '98:4b:e1:5b:73:2c',
            related_if => undef,
            driver     => 'iexgbe'
        }
    },
);

my %netstat_tests = (
    hpux => {
        lan0 => [
            {
                MTU         => '32808',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lan0',
                TYPE        => 'ethernet',
                IPADDRESS   => '172.24.70.121'
            }
        ],
        lo0 => [
            {
                MTU         => '32808',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lo0',
                TYPE        => 'ethernet',
                IPADDRESS   => '127.0.0.1'
            }
          ]

    },
    hpux1 => {
        lan0 => [
            {
                MTU         => '4136',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lan0',
                TYPE        => 'ethernet',
                IPADDRESS   => '10.0.4.55'
            },
            {
                MTU         => '4136',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lan0',
                TYPE        => 'ethernet',
                IPADDRESS   => '10.0.4.56'
            }
        ],
        lo0 => [
            {
                MTU         => '4136',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lo0',
                TYPE        => 'ethernet',
                IPADDRESS   => '127.0.0.1'
            }
          ]

    },
    hpux2 => {
        lan0 => [
            {
                MTU         => '4136',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lan0',
                TYPE        => 'ethernet',
                IPADDRESS   => '10.0.3.60'
            }
        ],
        lo0 => [
            {
                MTU         => '4136',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lo0',
                TYPE        => 'ethernet',
                IPADDRESS   => '127.0.0.1'
            }
          ]
    },
    hpux3 => {
        lan5000 => [
            {
                MTU         => '32808',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lan5000',
                TYPE        => 'ethernet',
                IPADDRESS   => '10.46.236.71'
            },
            {
                MTU         => '32808',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lan5000',
                TYPE        => 'ethernet',
                IPADDRESS   => '10.46.236.121'
            }
        ],
        lan5001 => [
            {
                MTU         => '32808',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lan5001',
                TYPE        => 'ethernet',
                IPADDRESS   => '10.46.228.71'
            }
        ],
        lo0 => [
            {
                MTU         => '32808',
                IPGATEWAY   => undef,
                IPMASK      => '255.255.255.255',
                DESCRIPTION => 'lo0',
                TYPE        => 'ethernet',
                IPADDRESS   => '127.0.0.1'
            }
        ]
    }
);

my %lanscan_tests = (
    hpux => [
        {
            lan_id      => '1',
            DESCRIPTION => 'lan1',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:a4'
        },
        {
            lan_id      => '10',
            DESCRIPTION => 'lan10',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:e8'
        },
        {
            lan_id      => '11',
            DESCRIPTION => 'lan11',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:ec'
        },
        {
            lan_id      => '12',
            DESCRIPTION => 'lan12',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:c6:be'
        },
        {
            lan_id      => '13',
            DESCRIPTION => 'lan13',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:c6:c2'
        },
        {
            lan_id      => '14',
            DESCRIPTION => 'lan14',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:c6:bf'
        },
        {
            lan_id      => '15',
            DESCRIPTION => 'lan15',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:c6:c3'
        },
        {
            lan_id      => '2',
            DESCRIPTION => 'lan2',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:a8'
        },
        {
            lan_id      => '3',
            DESCRIPTION => 'lan3',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:ac'
        },
        {
            lan_id      => '16',
            DESCRIPTION => 'lan16',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:f0'
        },
        {
            lan_id      => '17',
            DESCRIPTION => 'lan17',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:f4'
        },
        {
            lan_id      => '18',
            DESCRIPTION => 'lan18',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:c6:c6'
        },
        {
            lan_id      => '19',
            DESCRIPTION => 'lan19',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:c6:ca'
        },
        {
            lan_id      => '20',
            DESCRIPTION => 'lan20',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:c6:c7'
        },
        {
            lan_id      => '21',
            DESCRIPTION => 'lan21',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:c6:cb'
        },
        {
            lan_id      => '22',
            DESCRIPTION => 'lan22',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:f8'
        },
        {
            lan_id      => '37',
            DESCRIPTION => 'lan37',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:fc'
        },
        {
            lan_id      => '23',
            DESCRIPTION => 'lan23',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => 'd8:d3:85:d8:14:62'
        },
        {
            lan_id      => '38',
            DESCRIPTION => 'lan38',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => 'd8:d3:85:d8:14:66'
        },
        {
            lan_id      => '24',
            DESCRIPTION => 'lan24',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => 'd8:d3:85:d8:14:63'
        },
        {
            lan_id      => '39',
            DESCRIPTION => 'lan39',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => 'd8:d3:85:d8:14:67'
        },
        {
            lan_id      => '6',
            DESCRIPTION => 'lan6',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:a2'
        },
        {
            lan_id      => '7',
            DESCRIPTION => 'lan7',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:a6'
        },
        {
            lan_id      => '25',
            DESCRIPTION => 'lan25',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:b2'
        },
        {
            lan_id      => '26',
            DESCRIPTION => 'lan26',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:e6'
        },
        {
            lan_id      => '27',
            DESCRIPTION => 'lan27',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:f2'
        },
        {
            lan_id      => '28',
            DESCRIPTION => 'lan28',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:f6'
        },
        {
            lan_id      => '29',
            DESCRIPTION => 'lan29',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:e6:4b'
        },
        {
            lan_id      => '30',
            DESCRIPTION => 'lan30',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:e6:4f'
        },
        {
            lan_id      => '8',
            DESCRIPTION => 'lan8',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:aa'
        },
        {
            lan_id      => '9',
            DESCRIPTION => 'lan9',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:ae'
        },
        {
            lan_id      => '31',
            DESCRIPTION => 'lan31',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:ea'
        },
        {
            lan_id      => '32',
            DESCRIPTION => 'lan32',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:ee'
        },
        {
            lan_id      => '33',
            DESCRIPTION => 'lan33',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:fa'
        },
        {
            lan_id      => '34',
            DESCRIPTION => 'lan34',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:fe'
        },
        {
            lan_id      => '35',
            DESCRIPTION => 'lan35',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:e6:53'
        },
        {
            lan_id      => '36',
            DESCRIPTION => 'lan36',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '1c:c1:de:40:e6:57'
        },
        {
            lan_id      => '900',
            DESCRIPTION => 'lan900',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:a0'
        },
        {
            lan_id      => '901',
            DESCRIPTION => 'lan901',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:00:00:00:00:00'
        },
        {
            lan_id      => '902',
            DESCRIPTION => 'lan902',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:17:a4:77:08:b0'
        },
        {
            lan_id      => '903',
            DESCRIPTION => 'lan903',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:00:00:00:00:00'
        },
        {
            lan_id      => '904',
            DESCRIPTION => 'lan904',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:00:00:00:00:00'
        }
    ],
    hpux1 => [
        {
            lan_id      => '0',
            DESCRIPTION => 'lan0',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:16:35:3e:ac:5c'
        },
        {
            lan_id      => '1',
            DESCRIPTION => 'lan1',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:16:35:3e:ac:5d'
        }
    ],
    hpux2 => [
        {
            lan_id      => '0',
            DESCRIPTION => 'lan0',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:16:35:3e:ac:44'
        },
        {
            lan_id      => '1',
            DESCRIPTION => 'lan1',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:16:35:3e:ac:45'
        },
        {
            lan_id      => '900',
            DESCRIPTION => 'lan900',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:00:00:00:00:00'
        },
        {
            lan_id      => '901',
            DESCRIPTION => 'lan901',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:00:00:00:00:00'
        },
        {
            lan_id      => '902',
            DESCRIPTION => 'lan902',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:00:00:00:00:00'
        },
        {
            lan_id      => '903',
            DESCRIPTION => 'lan903',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:00:00:00:00:00'
        },
        {
            lan_id      => '904',
            DESCRIPTION => 'lan904',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => '00:00:00:00:00:00'
        }
    ]
);

plan tests =>
    (scalar keys %lanadmin_tests) +
    (scalar keys %ifconfig_tests) +
    (scalar keys %nwmgr_tests) +
    (scalar keys %netstat_tests) +
    (2 * scalar keys %lanscan_tests) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %lanadmin_tests) {
    my $file = "resources/hpux/lanadmin/$test";
    my $info = GLPI::Agent::Task::Inventory::HPUX::Networks::_getLanadminInfo(file => $file);
    cmp_deeply($info, $lanadmin_tests{$test}, "lanadmin parsing: $test");
}

foreach my $test (keys %ifconfig_tests) {
    my $file = "resources/generic/ifconfig/$test";
    my $info = GLPI::Agent::Task::Inventory::HPUX::Networks::_getIfconfigInfo(file => $file);
    cmp_deeply($info, $ifconfig_tests{$test}, "ifconfig parsing: $test");
}

foreach my $test (keys %nwmgr_tests) {
    my $file = "resources/hpux/nwmgr/$test";
    my $info = GLPI::Agent::Task::Inventory::HPUX::Networks::_getNwmgrInfo(file => $file);
    cmp_deeply($info, $nwmgr_tests{$test}, "nwmgr parsing: $test");
}

foreach my $test (keys %netstat_tests) {
    my $file = "resources/hpux/netstat/$test";
    my %interfaces = GLPI::Agent::Task::Inventory::HPUX::Networks::_parseNetstatNrv(file => $file);
    cmp_deeply(\%interfaces, $netstat_tests{$test}, "netstat -nrv parsing: $test");
}

foreach my $test (keys %lanscan_tests) {
    my $file = "resources/hpux/lanscan/$test";
    my @interfaces = GLPI::Agent::Task::Inventory::HPUX::Networks::_parseLanscan(file => $file);
    cmp_deeply(\@interfaces, $lanscan_tests{$test}, "lanscan -iap parsing: $test");
    delete $_->{lan_id} foreach @interfaces;
    lives_ok {
        $inventory->addEntry(section => 'NETWORKS', entry => $_)
            foreach @interfaces;
    } "$test: registering";
}
