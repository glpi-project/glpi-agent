#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::NoWarnings;
use Test::MockModule;
use Test::Deep qw(cmp_deeply);
use Test::Exception;

use GLPI::Agent::Config;
use GLPI::Agent::Logger;
use GLPI::Agent::Inventory;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Linux;
use GLPI::Agent::Task::Inventory::Linux::Networks;

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

# %system describes the tested system
my %system = (
    'sample-1' => {
        '/proc/net/dev' => 'Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo: 138468463  621772    0    0    0     0          0         0 138468463  621772    0    0    0     0       0          0
  eth0: 1234567   12345    1    0    0     0          0         0 8765432   87654    2    0    0     0       0          0',
        '/sbin/ip'          => 1, # canRun() result
        '/sbin/ifconfig'    => 1, # canRun() result
        '/sbin/ip addr show'    => '1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether fe:61:93:ef:1b:59 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.1/24 brd 192.168.0.255 scope global dynamic noprefixroute eth0
       valid_lft 29251sec preferred_lft 29251sec',
    }
);

my %interfaces = (
    'sample-1' => [
        {
            DESCRIPTION => 'lo',
            IPDHCP      => undef,
            VIRTUALDEV  => 1,
            MACADDR     => '00:00:00:00:00:00',
            IFINBYTES   => '138468463',
            IFINERRORS  => '0',
            IFOUTBYTES  => '138468463',
            IFOUTERRORS => '0',
            TYPE        => 'loopback',
            STATUS      => 'Up',
            IPADDRESS   => '127.0.0.1',
            IPMASK      => '255.0.0.0',
            IPSUBNET    => '127.0.0.0',
        },
        {
            DESCRIPTION => 'eth0',
            IPDHCP      => undef,
            IPSUBNET    => undef,
            VIRTUALDEV  => 1,
            STATUS      => 'Up',
            MACADDR     => 'fe:61:93:ef:1b:59',
            IFINBYTES   => '1234567',
            IFINERRORS  => '1',
            IFOUTBYTES  => '8765432',
            IFOUTERRORS => '2',
            IPADDRESS   => '192.168.0.1',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '192.168.0.0',
        },
    ]
);

plan tests => (scalar keys %tests) + (2 * scalar keys %interfaces) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/linux/iwconfig/$test";
    my $info = GLPI::Agent::Task::Inventory::Linux::Networks::_parseIwconfig(file => $file);
    cmp_deeply($info, $tests{$test}, "$test: _parseIwconfig()");
}

my $logger = GLPI::Agent::Logger->new(
    config => GLPI::Agent::Config->new(
        options => {
            config => 'none',
            logger => 'Test'
        }
    )
);


my $linux_tools = Test::MockModule->new('GLPI::Agent::Tools::Linux');
my $linux_net = Test::MockModule->new('GLPI::Agent::Task::Inventory::Linux::Networks');

foreach my $test (keys(%interfaces)) {

    # Mock APIs
    $linux_net->mock('canRead', sub {
        return $system{$test}->{$_[0]};
    });
    $linux_net->mock('canRun', sub {
        return $system{$test}->{$_[0]};
    });
    $linux_net->mock('has_folder', sub {
        return $system{$test}->{$_[0]};
    });
    $linux_net->mock('getAllLines', sub {
        my %params = @_;
        my $content = delete $params{command} || delete $params{file};
        $params{string} = $system{$test}->{$content}
            unless empty($content) || empty($system{$test}->{$content});
        return $linux_net->original('getAllLines')->(%params);
    });
    $linux_tools->mock('getAllLines', sub {
        my %params = @_;
        my $content = delete $params{command} || delete $params{file};
        $params{string} = $system{$test}->{$content}
            unless empty($content) || empty($system{$test}->{$content});
        return $linux_tools->original('getAllLines')->(%params);
    });

    my @interfaces = GLPI::Agent::Task::Inventory::Linux::Networks::_getInterfaces(
        glpi12_support  => 1,
        logger          => $logger
    );

    cmp_deeply(
        \@interfaces,
        $interfaces{$test},
        "$test: Linux network interfaces"
    );

    my $inventory = GLPI::Agent::Inventory->new(glpi => '12.0.0');
    lives_ok {
        foreach my $port (@interfaces) {
            $inventory->addEntry(
                section => 'NETWORKS',
                entry   => $port
            );
        }
    } "$test: addEntry() doesn't throw exceptions for Linux networks";
}
