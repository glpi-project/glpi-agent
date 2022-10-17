#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;
use Test::MockModule;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::PCI::Videos;
use GLPI::Agent::Task::Inventory::Generic::PCI::Videos::Nvidia;

my %tests = (
    'nvidia-1' => [
        {
            CHIPSET     => 'NVIDIA Corporation TU106',
            NAME        => 'NVIDIA Corporation GeForce RTX 2060 SUPER',
            MEMORY      => '8192',
            PCIID       => '10de:1f06',
            PCISLOT     => '09:00.0',
            RESOLUTION  => '1920x1080',
        }
    ],
    'linux-asus-portable' => [
        {
            CHIPSET     => 'NVIDIA Corporation TU117M',
            NAME        => 'NVIDIA Corporation GeForce GTX 1650 Mobile / Max-Q',
            MEMORY      => '4096',
            PCIID       => '10de:1f9d',
            PCISLOT     => '01:00.0',
        },
    ],
);

my %merged = (
    'nvidia-1' => {
        origin => [
            {
                CHIPSET     => 'NVIDIA Corporation TU106',
                NAME        => 'PNY GeForce RTX 2060 SUPER',
                MEMORY      => '288',
                PCIID       => '10de:1f06',
                PCISLOT     => '09:00.0',
            }
        ],
        merged => [
            {
                CHIPSET     => 'NVIDIA Corporation TU106',
                NAME        => 'PNY GeForce RTX 2060 SUPER',
                MEMORY      => '8192',
                PCIID       => '10de:1f06',
                PCISLOT     => '09:00.0',
                RESOLUTION  => '1920x1080',
            }
        ],
    },
    'linux-asus-portable' => {
        origin => [
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
        ],
        merged => [
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
                MEMORY      => '4096',
                PCIID       => '10de:1f9d',
                PCISLOT     => '0000:01:00.0',
            }
        ],
    },
);

plan tests => (2 * scalar keys %tests) +  (3 * scalar keys %merged) + 1;

my $module = Test::MockModule->new('GLPI::Agent::Task::Inventory::Generic::PCI::Videos::Nvidia');

foreach my $test (keys %tests) {
    my %params = ( file => "resources/generic/lspci/$test.nvidia-settings" );
    $params{gpus} = 1 if -e $params{file}.".gpus";
    my @videos = GLPI::Agent::Task::Inventory::Generic::PCI::Videos::Nvidia::_getNvidiaVideos(%params);
    cmp_deeply(\@videos, $tests{$test}, $test);
    lives_ok {
        my $inventory = GLPI::Test::Inventory->new();
        $inventory->addEntry(section => 'VIDEOS', entry => $_)
            foreach @videos;
    } "$test: registering";
}

foreach my $test (keys %merged) {
    my %params = ( file => "resources/generic/lspci/$test" );

    # Populate inventory with lspci parsing
    my $inventory = GLPI::Test::Inventory->new();
    my @videos = GLPI::Agent::Task::Inventory::Generic::PCI::Videos::_getVideos(%params);
    $inventory->addEntry(section => 'VIDEOS', entry => $_)
        foreach @videos;
    cmp_deeply(\@videos, $merged{$test}->{origin}, "pci $test inventory");

    $params{file} .= ".nvidia-settings";
    $params{gpus} = 1 if -e $params{file}.".gpus";
    @videos = GLPI::Agent::Task::Inventory::Generic::PCI::Videos::Nvidia::_getNvidiaVideos(%params);
    $module->mock('_getNvidiaVideos', sub { return @videos; });

    lives_ok {
        GLPI::Agent::Task::Inventory::Generic::PCI::Videos::Nvidia::doInventory(inventory => $inventory);
    } "$test: doing inventory";

    my $videos = $inventory->getSection('VIDEOS');
    cmp_deeply($videos, $merged{$test}->{merged}, "merged $test inventory");

    $module->unmock_all();
}
