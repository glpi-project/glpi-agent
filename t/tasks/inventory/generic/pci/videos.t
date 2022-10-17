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
            CHIPSET => 'VGA compatible controller',
            MEMORY  => '256',
            PCIID   => '8086:2a42',
            PCISLOT => '00:02.0',
        },
        {
            NAME    => 'Intel Corporation Mobile 4 Series Chipset Integrated Graphics Controller',
            CHIPSET => 'Display controller',
            PCIID   => '8086:2a43',
            PCISLOT => '00:02.1',
        }
    ],
    'linux-2' => [
        {
            CHIPSET => 'NVIDIA Corporation NV43GL',
            NAME    => 'NVIDIA Corporation Quadro FX 550',
            MEMORY  => '128',
            PCIID   => '10de:014d',
            PCISLOT => '01:00.0',
        }
    ],
    'nvidia-1' => [
        {
            CHIPSET     => 'NVIDIA Corporation TU106',
            NAME        => 'PNY GeForce RTX 2060 SUPER',
            MEMORY      => '288',
            PCIID       => '10de:1f06',
            PCISLOT     => '09:00.0',
            RESOLUTION  => '1920x1080',
        }
    ],
    'linux-imac' => [
        {
            CHIPSET     => 'Advanced Micro Devices, Inc. [AMD/ATI] RV730/M96-XT',
            NAME        => 'Apple Inc. Mobility Radeon HD 4670',
            MEMORY      => '256',
            PCIID       => '1002:9488',
            PCISLOT     => '01:00.0',
            RESOLUTION  => '1920x1080',
        }
    ],
    'linux-xps' => [
        {
            CHIPSET     => 'Intel Corporation Skylake GT2',
            NAME        => 'Dell HD Graphics 520',
            MEMORY      => '256',
            PCIID       => '8086:1916',
            PCISLOT     => '00:02.0',
            RESOLUTION  => '1680x1050',
        }
    ],
    'linux-asus-portable' => [
        {
            CHIPSET     => 'Intel Corporation TigerLake-LP GT2',
            NAME        => 'ASUSTeK Computer Inc. Iris Xe Graphics',
            MEMORY      => '256',
            PCIID       => '8086:9a49',
            PCISLOT     => '0000:00:02.0',
        },
        {
            CHIPSET     => 'NVIDIA Corporation TU117M',
            NAME        => 'ASUSTeK Computer Inc. GeForce GTX 1650 Mobile / Max-Q',
            MEMORY      => '288',
            PCIID       => '10de:1f9d',
            PCISLOT     => '0000:01:00.0',
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my %params = ( file => "resources/generic/lspci/$test" );
    $params{xrandr}   = 1 if -e $params{file}.".xrandr";
    $params{xdpyinfo} = 1 if -e $params{file}.".xdpyinfo";
    my @videos = GLPI::Agent::Task::Inventory::Generic::PCI::Videos::_getVideos(%params);
    cmp_deeply(\@videos, $tests{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'VIDEOS', entry => $_)
            foreach @videos;
    } "$test: registering";
}
