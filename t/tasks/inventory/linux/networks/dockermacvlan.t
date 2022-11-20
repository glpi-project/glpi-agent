#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::Networks::DockerMacvlan;

my %tests = (
    'docker-network-ls' => [
        'c9e960a0c68b'
    ],
    'docker-network-inspect' => [
        {
            IPADDRESS   => '10.20.210.171',
            IPMASK      => '255.255.255.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            DESCRIPTION => 'pinba_network@pinbatwo-bmashard1',
            MACADDR     => '02:42:0a:14:d2:ab',
            VIRTUALDEV  => 1
        },
        {
            IPADDRESS   => '10.20.210.162',
            IPMASK      => '255.255.255.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            DESCRIPTION => 'pinba_network@pinbatwo-staging1',
            MACADDR     => '02:42:0a:14:d2:a2',
            VIRTUALDEV  => 1
        },
        {
            IPADDRESS   => '10.20.210.153',
            IPMASK      => '255.255.255.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            DESCRIPTION => 'pinba_network@pinbatwo-www1',
            MACADDR     => '02:42:0a:14:d2:99',
            VIRTUALDEV  => 1
        },
        {
            IPADDRESS   => '10.20.210.160',
            IPMASK      => '255.255.255.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            DESCRIPTION => 'pinba_network@pinbatwo-cpp2',
            MACADDR     => '02:42:0a:14:d2:a0',
            VIRTUALDEV  => 1
        },
    ],
);

plan tests => (scalar keys %tests) + 1;

my $test = 'docker-network-ls';
my $file = "resources/linux/docker/$test";
my @networks = GLPI::Agent::Task::Inventory::Linux::Networks::DockerMacvlan::_getMacvlanNetworks(file => $file);
cmp_deeply(\@networks, $tests{$test}, $test);

$test = 'docker-network-inspect';
$file = "resources/linux/docker/$test";
my @interfaces = GLPI::Agent::Task::Inventory::Linux::Networks::DockerMacvlan::_getInterfaces(file => $file, networkId => "");
cmp_set(\@interfaces, $tests{$test}, $test);
