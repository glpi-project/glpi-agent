#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::AIX::Videos;

my %tests = (
    'aix-4.3.1' => [],
    'aix-4.3.2' => [],
    'aix-5.3a'  => [
        {
            NAME => 'lai0',
        }
    ],
    'aix-5.3b' => [],
    'aix-5.3c' => [],
    'aix-6.1a' => [],
    'aix-6.1b' => [
        {
            NAME => 'ati0',
        }
    ]
);

plan tests => (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/aix/lsdev/$test-adapter";
    my @videos = GLPI::Agent::Task::Inventory::AIX::Videos::_getVideos(file => $file);
    cmp_deeply(\@videos, $tests{$test}, "videos: $test");
}
