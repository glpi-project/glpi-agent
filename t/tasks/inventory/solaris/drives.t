#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Solaris::Drives;

my %tests = (
    'zfs-samples' => [
        {
            FILESYSTEM  => 'zfs',
            FREE        => 15274,
            TOTAL       => 22051,
            TYPE        => '/',
            VOLUMN      => '/'
        },
        {
            FILESYSTEM  => 'zfs',
            FREE        => 460333,
            TOTAL       => 460356,
            TYPE        => '/dump',
            VOLUMN      => 'Z_FS_DATAPOOL/Z_FS_LV_DUMP'
        },
        {
            FILESYSTEM  => 'zfs',
            FREE        => 511,
            TOTAL       => 511,
            TYPE        => '/kba',
            VOLUMN      => 'Z_FS_DATAPOOL/lv_kba'
        },
        {
            FILESYSTEM  => 'zfs',
            FREE        => 460333,
            TOTAL       => 460338,
            TYPE        => '/oracle',
            VOLUMN      => 'Z_FS_DATAPOOL/Z_FS_LV_ORACLE'
        },
        {
            FILESYSTEM  => 'swap',
            FREE        => 64126,
            TOTAL       => 64126,
            TYPE        => '/etc/svc/volatile',
            VOLUMN      => 'swap'
        },
        {
            FILESYSTEM  => 'swap',
            FREE        => 64126,
            TOTAL       => 64127,
            TYPE        => '/tmp',
            VOLUMN      => 'swap'
        },
        {
            FILESYSTEM  => 'swap',
            FREE        => 64126,
            TOTAL       => 64126,
            TYPE        => '/var/run',
            VOLUMN      => 'swap'
        }
    ],
);

plan tests => (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $inventory = GLPI::Test::Inventory->new();
    GLPI::Agent::Task::Inventory::Solaris::Drives::doInventory(
        inventory   => $inventory,
        file        => "resources/solaris/df/$test",
        df_version  => $test,
        mount_res   => "resources/solaris/mount/$test"
    );
    cmp_deeply($inventory->getSection('DRIVES'), $tests{$test}, "$test: parsing");
}
