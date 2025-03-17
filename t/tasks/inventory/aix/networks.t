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
        'en0' => '08:00:5a:ba:e9:67',
    },
    'aix-4.3.2' => {
        'en1' => '00:20:35:b5:8b:46',
        'en0' => '08:00:5a:ba:eb:da',
    },
    'aix-5.3a' => {
        'en0' => '00:14:5e:4d:20:c6',
        'en1' => '00:14:5e:4d:20:c7',
    },
    'aix-5.3b' => {
            'en0' => '00:14:5e:9c:93:00',
            'en1' => '00:14:5e:9c:93:01',
    },
    'aix-5.3c' => {
        'en0' => '00:21:5e:0b:42:78',
        'en1' => '00:21:5e:0b:42:79',
        'en2' => '8e:72:9c:98:e6:04',
    },
    'aix-6.1a' => {
        'en0' => 'd2:13:c0:15:3a:04',
        'en1' => '00:21:5e:a6:7c:c0',
        'en2' => '00:21:5e:a6:7c:d0',
    },
    'aix-6.1b' => {
        'en0' => '00:21:5e:4c:c7:68',
        'en1' => '00:21:5e:4c:c7:69',
        'en2' => '00:1a:64:86:42:30',
        'en3' => '00:1a:64:86:42:31',
    }
);

plan tests => (scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/aix/lscfg/$test-en";
    my %addresses = GLPI::Agent::Task::Inventory::AIX::Networks::_parseLscfg(file => $file);
    cmp_deeply(\%addresses, $tests{$test}, "$test: parsing");
}
