#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::AIX::Networks;

my %tests = (
    'aix-4.3.1' => {
        'en0' => '08:00:5A:BA:E9:67',
    },
    'aix-4.3.2' => {
        'en1' => '00:20:35:B5:8B:46',
        'en0' => '08:00:5A:BA:EB:DA',
    },
    'aix-5.3a' => {
        'en0' => '00:14:5E:4D:20:C6',
        'en1' => '00:14:5E:4D:20:C7',
    },
    'aix-5.3b' => {
            'en0' => '00:14:5E:9C:93:00',
            'en1' => '00:14:5E:9C:93:01',
    },
    'aix-5.3c' => {
        'en0' => '00:21:5E:0B:42:78',
        'en1' => '00:21:5E:0B:42:79',
        'en2' => '8E:72:9C:98:E6:04',
    },
    'aix-6.1a' => {
        'en0' => 'D2:13:C0:15:3A:04',
        'en1' => '00:21:5E:A6:7C:C0',
        'en2' => '00:21:5E:A6:7C:D0',
    },
    'aix-6.1b' => {
        'en0' => '00:21:5E:4C:C7:68',
        'en1' => '00:21:5E:4C:C7:69',
        'en2' => '00:1A:64:86:42:30',
        'en3' => '00:1A:64:86:42:31',
    }
);

plan tests => (scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/aix/lscfg/$test-en";
    my %addresses = GLPI::Agent::Task::Inventory::AIX::Networks::_parseLscfg(file => $file);
    cmp_deeply(\%addresses, $tests{$test}, "$test: parsing");
}
