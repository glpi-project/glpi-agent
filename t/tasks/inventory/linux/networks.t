#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::More;
use Test::NoWarnings;

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

plan tests => (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/linux/iwconfig/$test";
    my $info = GLPI::Agent::Task::Inventory::Linux::Networks::_parseIwconfig(file => $file);
    cmp_deeply($info, $tests{$test}, $test);
}
