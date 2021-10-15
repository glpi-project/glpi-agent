#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::Drives;

my %hal_tests = (
    'dell-xt2' => [
        {
            VOLUMN => '/dev/',
            TOTAL  => 44814
        },
        {
            VOLUMN     => '/dev/sda7',
            TOTAL      => 44814,
            SERIAL     => 'f75b1fa9-1109-46b4-abde-541af44ed8cd',
            FILESYSTEM => 'crypto_LUKS'
        },
        {
            VOLUMN     => '/dev/sda6',
            TOTAL      => 3993,
            SERIAL     => '3aebfe11-8dba-4c61-87b1-10f391dba4fc',
            LABEL      => 'swap',
            FILESYSTEM => 'swap'
        },
        {
            VOLUMN => '/dev/sda4',
            TOTAL  => 0
        },
        {
            VOLUMN     => '/dev/sda5',
            TOTAL      => 12300,
            SERIAL     => '7a20e641-ec5f-41ff-8c7b-2056b18cae80',
            LABEL      => 'root',
            FILESYSTEM => 'ext4'
        },
        {
            VOLUMN     => '/dev/sda3',
            TOTAL      => 60003,
            SERIAL     => '5A60194E6019326D',
            LABEL      => 'OS',
            FILESYSTEM => 'ntfs-3g'
        },
        {
            VOLUMN     => '/dev/sda2',
            TOTAL      => 750,
            SERIAL     => 'CCE616B2E6169CB0',
            LABEL      => 'RECOVERY',
            FILESYSTEM => 'ntfs-3g'
        },
        {
            VOLUMN     => '/dev/sda1',
            TOTAL      => 243,
            SERIAL     => '07DA-0305',
            LABEL      => 'DellUtility',
            FILESYSTEM => 'vfat'
        }
    ],
    'rh4-kvm' => [
        {
            VOLUMN     => '/dev/hda1',
            TOTAL      => 102,
            LABEL      => '/boot',
            SERIAL     => 'a946b73c-79a1-4498-a5f4-ae241426954f',
            FILESYSTEM => 'ext3'
        },
        {
            VOLUMN     => '/dev/hda2',
            TOTAL      => 10135,
            FILESYSTEM => 'LVM2_member'
        },
    ]
);

plan tests => (2 * scalar keys %hal_tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %hal_tests) {
    my $file = "resources/linux/hal/$test";
    my $drives = GLPI::Agent::Task::Inventory::Linux::Drives::_parseLshal(file => $file);
    cmp_deeply($drives, $hal_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'DRIVES', entry => $_) foreach @$drives;
    } "$test: registering";
}
