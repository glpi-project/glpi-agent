#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::Networks::iLO;

my %tests = (
    'sample1' => {
        IPGATEWAY   => '192.168.10.254',
        IPMASK      => '255.255.248.0',
        STATUS      => 'Up',
        SPEED       => '10',
        TYPE        => 'ethernet',
        IPSUBNET    => '192.168.8.0',
        MANAGEMENT  => 'iLO',
        DESCRIPTION => 'Management Interface - HP iLO',
        IPADDRESS   => '192.168.10.1'
    },
    'sample2' => {
        STATUS      => 'Down',
        TYPE        => 'ethernet',
        MANAGEMENT  => 'iLO',
        DESCRIPTION => 'Management Interface - HP iLO',
    },
    'sample3' => {
        STATUS      => 'Up',
        TYPE        => 'ethernet',
        MANAGEMENT  => 'iLO',
        DESCRIPTION => 'Management Interface - HP iLO',
        IPMASK      => '255.255.254.0',
    },
    'sample4' => {
        STATUS      => 'Down',
        TYPE        => 'ethernet',
        MANAGEMENT  => 'iLO',
        DESCRIPTION => 'Management Interface - HP iLO',
        SPEED       => '10',
        IPGATEWAY   => '192.168.51.254',
        IPADDRESS   => '192.168.50.84',
        IPMASK      => '255.255.254.0',
        IPSUBNET    => '192.168.50.0'
    },
    'sample3+4' => {
        STATUS      => 'Up',
        TYPE        => 'ethernet',
        MANAGEMENT  => 'iLO',
        DESCRIPTION => 'Management Interface - HP iLO',
        SPEED       => '10',
        IPGATEWAY   => '192.168.51.254',
        IPADDRESS   => '192.168.50.84',
        IPMASK      => '255.255.254.0',
        IPSUBNET    => '192.168.50.0'
    }
);

plan tests => (2 * scalar keys %tests) + 1 + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/linux/hponcfg/$test";
    my $interface = GLPI::Agent::Task::Inventory::Generic::Networks::iLO::_parseHponcfg(file => $file);
    cmp_deeply($interface, $tests{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'NETWORKS', entry => $interface);
    } 'no unknown fields';
}

# Test merge of sample3 + sampl4
my $file = "resources/linux/hponcfg/sample3";
my $interface = GLPI::Agent::Task::Inventory::Generic::Networks::iLO::_parseHponcfg(file => $file);
$file = "resources/linux/hponcfg/sample4";
$interface = GLPI::Agent::Task::Inventory::Generic::Networks::iLO::_parseHponcfg(file => $file, entry => $interface);
cmp_deeply($interface, $tests{'sample3+4'}, 'sample3 & sample4 merged');
