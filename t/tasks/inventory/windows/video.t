#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More;
use Test::NoWarnings;
use UNIVERSAL::require;

use GLPI::Agent::Inventory;
use GLPI::Test::Utils;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

GLPI::Agent::Task::Inventory::Win32::Videos->require();

my %tests = (
    'amd-radeon-rx6600xt' => [
        {
            CHIPSET     => 'AMD Radeon Graphics Processor (0x73FF)',
            MEMORY      => 8176,
            NAME        => 'AMD Radeon RX 6600 XT',
            RESOLUTION  => '1920x1080',
        }
    ],
    'nvidia-geforce-rtx-2060-super' => [
        {
            CHIPSET     => 'NVIDIA GeForce RTX 2060 SUPER',
            MEMORY      => 8192,
            NAME        => 'NVIDIA GeForce RTX 2060 SUPER',
            RESOLUTION  => '1920x1080',
        }
    ],
    'intel+nvidia' => [
        {
            CHIPSET     => undef,
            MEMORY      => undef,
            NAME        => 'Microsoft Remote Display Adapter',
            RESOLUTION  => '1920x1080',
        }, {
            CHIPSET     => 'Intel(R) HD Graphics Family',
            MEMORY      => 1024,
            NAME        => 'Intel(R) HD Graphics 4600',
            RESOLUTION  => '1920x1200',
        }, {
            CHIPSET     => 'NVIDIA GeForce GTX 950',
            MEMORY      => 2048,
            NAME        => 'NVIDIA GeForce GTX 950',
            RESOLUTION  => '1920x1200',
        }
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new();

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::Videos'
);

my $tools_module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);

foreach my $test (keys %tests) {
    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    $tools_module->mock(
        '_getRegistryKey',
        mockGetRegistryKey($test)
    );

    my @videos = GLPI::Agent::Task::Inventory::Win32::Videos::_getVideos();
    cmp_deeply(
        \@videos,
        $tests{$test},
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'VIDEOS', entry => $_)
            foreach @videos;
    } "$test: registering";
}
