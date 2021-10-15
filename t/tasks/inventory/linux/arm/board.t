#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;

use GLPI::Agent::Task::Inventory::Linux::ARM::Board;

my %arm = (
    'linux-armel-1' => [
        # Expected infos from cpuinfo
        {
            'hardware'  => "Thecus N2100",
            'revision'  => "0000",
            'serial'    => "0000000000000000"
        },
        # Expected board info to be set as Bios
        {
            MMODEL  => "Thecus N2100",
            MSN     => "0000",
            SSN     => "0000000000000000"
        },
    ],
    'linux-armel-2' => [
        {
            'hardware'  => "Marvell SheevaPlug Reference Board",
            'revision'  => "0000",
            'serial'    => "0000000000000000"
        },
        {
            MMODEL  => "Marvell SheevaPlug Reference Board",
            MSN     => "0000",
            SSN     => "0000000000000000"
        }
    ],
    'linux-armel-3' => [
        {
            'hardware'  => "BCM2708",
            'revision'  => "000e",
            'serial'    => "00000000717ea366"
        },
        {
            MMODEL  => "BCM2708",
            MSN     => "000e",
            SSN     => "00000000717ea366"
        }
    ],
    'linux-raspberry-pi-3-model-b' => [
        {
            'hardware'  => "BCM2835",
            'revision'  => "a22082",
            'serial'    => "00000000acf9d788"
        },
        {
            MMODEL  => "BCM2835",
            MSN     => "a22082",
            SSN     => "00000000acf9d788"
        }
    ],
    # Case without information as not arm board
    'linux-686-1' => [ { 'not-a-board' => 1 } , { MMODEL => 'not-a-board' } ]
);

plan tests => (3 * scalar keys %arm) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %arm) {
    my $file = "resources/linux/proc/cpuinfo/$test";
    my $board = GLPI::Agent::Task::Inventory::Linux::ARM::Board::_getBoardFromProc(file => $file)
        || { 'not-a-board' => 1 };
    cmp_deeply($board, $arm{$test}[0], $test);
    my $bios = GLPI::Agent::Task::Inventory::Linux::ARM::Board::_getBios(board => $board)
        || { MMODEL => 'not-a-board' };
    cmp_deeply($bios, $arm{$test}[1], $test);
    lives_ok {
        $inventory->setBios($bios);
    } 'no unknown fields';
}
