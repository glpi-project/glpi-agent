#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::MacOS::Videos;

my %tests = (
    '10.6.5-dual-monitor' => [
        {
            NAME        => 'ATI Radeon HD 5770',
            RESOLUTION  => '1920x1080',
            CHIPSET     => 'ATI Radeon HD 5770',
            MEMORY      => '1024',
            PCISLOT     => 'Slot-1'
        }
    ],
    'dual-display-#475' => [
        {
            NAME        => 'Intel HD Graphics 530',
            CHIPSET     => 'Intel HD Graphics 530',
            MEMORY      => '1536',
            PCISLOT     => 'Built-In'
        },
        {
            NAME        => 'Radeon Pro 450',
            RESOLUTION  => '2880x1800',
            CHIPSET     => 'AMD Radeon Pro 450',
            MEMORY      => '2048',
            PCISLOT     => 'PCIe'
        }
    ],
    'mojave-dual-video-cards' => [
        {
            NAME        => 'Intel HD Graphics 530',
            CHIPSET     => 'Intel HD Graphics 530',
            RESOLUTION  => '2880x1800',
            MEMORY      => '1536',
            PCISLOT     => 'Built-In'
        },
        {
            NAME        => 'Radeon Pro 450',
            CHIPSET     => 'AMD Radeon Pro 450',
            MEMORY      => '2048',
            PCISLOT     => 'PCIe'
        }
    ],
    'asus-geforce-gt-730' => [
        {
            MEMORY      => '1024',
            PCISLOT     => 'PCIe',
            RESOLUTION  => '1920x1080',
            CHIPSET     => 'Asus GeForce GT 730',
            NAME        => 'Asus GeForce GT 730'
        }
    ]
);

plan tests => scalar(keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/macos/system_profiler/$test";
    my @videos = GLPI::Agent::Task::Inventory::MacOS::Videos::_getVideoCards(file => $file);
    cmp_deeply(
        [ sort { compare_video() } @videos ],
        [ sort { compare_video() } @{$tests{$test}} ],
        "$test videos"
    );
}

sub compare_video {
    return
        $a->{NAME} cmp $b->{NAME};
}
