#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::PCI::Videos;

my %tests = (
    'dell-xt2' => [
        {
            NAME    => 'Intel Corporation Mobile 4 Series Chipset Integrated Graphics Controller',
            CHIPSET => 'VGA compatible controller'
        },
        {
            NAME    => 'Intel Corporation Mobile 4 Series Chipset Integrated Graphics Controller',
            CHIPSET => 'Display controller'
        }
    ],
    'linux-2' => [
        {
            CHIPSET => 'VGA compatible controller',
            NAME    => 'NVIDIA Corporation NV43GL [Quadro FX 550]'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/generic/lspci/$test";
    my @videos = GLPI::Agent::Task::Inventory::Generic::PCI::Videos::_getVideos(file => $file);
    cmp_deeply(\@videos, $tests{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'VIDEOS', entry => $_)
            foreach @videos;
    } "$test: registering";
}
