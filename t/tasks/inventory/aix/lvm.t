#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::AIX::LVM;

my %physical_volume_tests = (
    'aix-6.1-hdisk0' => {
        ATTR        => 'VG rootvg',
        DEVICE      => '/dev/aix-6.1-hdisk0',
        FORMAT      => 'AIX PV',
        FREE        => 10816,
        PE_SIZE     => 64,
        PV_PE_COUNT => 543,
        PV_UUID     => '00c6ce9d4f2c404a',
        SIZE        => 34752,
    },
    'aix-6.1-hdisk1' => {
        ATTR        => 'VG altinst_rootvg',
        DEVICE      => '/dev/aix-6.1-hdisk1',
        FORMAT      => 'AIX PV',
        PV_UUID     => '00c6ce9d53fc4e84',
    },
    'aix-6.1-hdisk2' =>{
        ATTR        => 'VG vg_apps01',
        DEVICE      => '/dev/aix-6.1-hdisk2',
        FORMAT      => 'AIX PV',
        FREE        => 12160,
        PE_SIZE     => 128,
        PV_PE_COUNT => 799,
        PV_UUID     => '00c6ce9d55b465a3',
        SIZE        => 102272,
    },
    'aix-6.1-hdisk3' => {
        ATTR        => 'VG vg_apps01',
        DEVICE      => '/dev/aix-6.1-hdisk3',
        FORMAT      => 'AIX PV',
        FREE        => 10112,
        PE_SIZE     => 128,
        PV_PE_COUNT => 239,
        PV_UUID     => '00c6ce9db4ee2922',
        SIZE        => 30592,
    },
);

my %logical_volume_tests = (
    'aix-6.1-hd1' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-hd1',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.8',
        SEG_COUNT => 8,
        SIZE      => 512
    },
    'aix-6.1-hd2' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-hd2',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.5',
        SEG_COUNT => 48,
        SIZE      => 3072
    },
    'aix-6.1-hd3' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-hd3',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.7',
        SEG_COUNT => 64,
        SIZE      => 4096
    },
    'aix-6.1-hd4' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-hd4',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.4',
        SEG_COUNT => 8,
        SIZE      => 512
    },
    'aix-6.1-hd5' => {
        ATTR      => 'Type boot',
        LV_NAME   => 'aix-6.1-hd5',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.1',
        SEG_COUNT => 1,
        SIZE      => 64
    },
    'aix-6.1-hd6' => {
        ATTR      => 'Type paging',
        LV_NAME   => 'aix-6.1-hd6',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.2',
        SEG_COUNT => 129,
        SIZE      => 8256
    },
    'aix-6.1-hd8' => {
        ATTR      => 'Type jfs2log',
        LV_NAME   => 'aix-6.1-hd8',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.3',
        SEG_COUNT => 1,
        SIZE      => 64
    },
    'aix-6.1-hd9var' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-hd9var',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.6',
        SEG_COUNT => 16,
        SIZE      => 1024
    },
    'aix-6.1-hd10opt' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-hd10opt',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.9',
        SEG_COUNT => 32,
        SIZE      => 2048
    },
    'aix-6.1-hd11admin' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-hd11admin',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.10',
        SEG_COUNT => 2,
        SIZE      => 128
    },
    'aix-6.1-fslv00' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-fslv00',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.14',
        SEG_COUNT => 2,
        SIZE      => 128
    },
    'aix-6.1-fslv01' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-fslv01',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.17',
        SEG_COUNT => 16,
        SIZE      => 1024
    },
    'aix-6.1-dooncelv' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-dooncelv',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.13',
        SEG_COUNT => 5,
        SIZE      => 320
    },
    'aix-6.1-lg_dumplv' => {
        ATTR      => 'Type sysdump',
        LV_NAME   => 'aix-6.1-lg_dumplv',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.11',
        SEG_COUNT => 20,
        SIZE      => 1280
    },
    'aix-6.1-livedump' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-livedump',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.12',
        SEG_COUNT => 4,
        SIZE      => 256
    },
    'aix-6.1-lv_auditlog' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-lv_auditlog',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.15',
        SEG_COUNT => 2,
        SIZE      => 128
    },
    'aix-6.1-lv_tpc' => {
        ATTR      => 'Type jfs2',
        LV_NAME   => 'aix-6.1-lv_tpc',
        LV_UUID   => '00c6ce9d00004c000000014302ee7629.16',
        SEG_COUNT => 16,
        SIZE      => 1024
    },
);

my %volume_group_tests = (
    'aix-6.x-rootvg' => {
        FREE           => '201',
        LV_COUNT       => '17',
        PV_COUNT       => '2',
        SIZE           => '798',
        VG_EXTENT_SIZE => '32',
        VG_NAME        => 'aix-6.x-rootvg',
        VG_UUID        => '000dda6e0000d600000001119e467657',
    }
);

plan tests =>
    (2 * scalar keys %physical_volume_tests) +
    (2 * scalar keys %logical_volume_tests) +
    (2 * scalar keys %volume_group_tests) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %physical_volume_tests) {
    my $file = "resources/aix/lspv/$test";
    my $device = GLPI::Agent::Task::Inventory::AIX::LVM::_getPhysicalVolume(file => $file, name => $test);
    cmp_deeply($device, $physical_volume_tests{$test}, "$test: lspv parsing");
    lives_ok {
        $inventory->addEntry(section => 'PHYSICAL_VOLUMES', entry => $device);
    } "$test: registering";
}

foreach my $test (keys %logical_volume_tests) {
    my $file = "resources/aix/lslv/$test";
    my $device = GLPI::Agent::Task::Inventory::AIX::LVM::_getLogicalVolume(file => $file, name => $test);
    cmp_deeply($device, $logical_volume_tests{$test}, "$test: lslv parsing");
    lives_ok {
        $inventory->addEntry(section => 'LOGICAL_VOLUMES', entry => $device);
    } "$test: registering";
}

foreach my $test (keys %volume_group_tests) {
    my $file = "resources/aix/lsvg/$test";
    my $device = GLPI::Agent::Task::Inventory::AIX::LVM::_getVolumeGroup(file => $file, name => $test);
    cmp_deeply($device, $volume_group_tests{$test}, "$test: lsvg parsing");
    lives_ok {
        $inventory->addEntry(section => 'VOLUME_GROUPS', entry => $device);
    } "$test: registering";
}
