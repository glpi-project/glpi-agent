#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Linux::Networks;
use GLPI::Agent::Inventory;
use Test::MockModule;

my %tests = (
    'sample1' => {
        version => '802.11abgn',
        mode    => 'Managed',
    },
    'sample2' => {
        SSID    => 'INRIA-roc',
        BSSID   => '00:0B:0E:8F:D0:43',
        version => '802.11abgn',
        mode    => 'Managed',
    }
);

plan tests => (scalar keys %tests) + 3;

foreach my $test (keys %tests) {
    my $file = "resources/linux/iwconfig/$test";
    my $info = GLPI::Agent::Task::Inventory::Linux::Networks::_parseIwconfig(file => $file);
    cmp_deeply($info, $tests{$test}, $test);
}

my $linux_net = Test::MockModule->new('GLPI::Agent::Task::Inventory::Linux::Networks');
$linux_net->mock('_getInterfacesBase', sub { return ({ DESCRIPTION => 'eth0' }); });

my $orig_getAllLines = $linux_net->original('getAllLines');
$linux_net->mock('getAllLines', sub {
    my (%params) = @_;
    if ($params{file} && $params{file} eq '/proc/net/dev') {
        return (
            'Inter-|   Receive                                                |  Transmit',
            ' face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed',
            '  eth0: 1234567   12345    1    0    0     0          0         0 8765432   87654    2    0    0     0       0          0'
        );
    }
    return $orig_getAllLines->(@_);
});

my @interfaces = GLPI::Agent::Task::Inventory::Linux::Networks::_getInterfaces(glpi12_support => 1);
cmp_deeply(
    $interfaces[0],
    {
        DESCRIPTION => 'eth0',
        IPDHCP      => undef,
        IPSUBNET    => undef,
        SPEED       => 0,
        VIRTUALDEV  => 1,
        IFINBYTES   => '1234567',
        IFINERRORS  => '1',
        IFOUTBYTES  => '8765432',
        IFOUTERRORS => '2',
    },
    "Linux network stats from /proc/net/dev mapped correctly"
);

my $inventory = GLPI::Agent::Inventory->new(glpi => '12.0.0');
eval {
    foreach my $port (@interfaces) {
        $inventory->addEntry(
            section => 'NETWORKS',
            entry   => $port
        );
    }
};
ok(!$@, "addEntry() doesn't throw exceptions for Linux networks");
