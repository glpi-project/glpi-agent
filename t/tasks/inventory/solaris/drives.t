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
    'oi-2021.10' => [
        {
            FREE        => 25123,
            TOTAL       => 31248,
            VOLUMN      => 'rpool/ROOT/openindiana',
            TYPE        => '/',
            FILESYSTEM  => 'zfs'
        },
        {
            TYPE        => '/etc/svc/volatile',
            VOLUMN      => 'swap',
            TOTAL       => 4859,
            FILESYSTEM  => 'swap',
            FREE        => 4858
        },
        {
            TYPE        => '/var',
            FREE        => 25123,
            TOTAL       => 31248,
            VOLUMN      => 'rpool/ROOT/openindiana/var',
            FILESYSTEM  => 'zfs'
        },
        {
            TYPE        => '/tmp',
            VOLUMN      => 'swap',
            FREE        => 4858,
            FILESYSTEM  => 'swap',
            TOTAL       => 4858
        },
        {
            TYPE        => '/var/run',
            TOTAL       => 4858,
            FREE        => 4858,
            FILESYSTEM  => 'swap',
            VOLUMN      => 'swap'
        },
        {
            TYPE        => '/export',
            TOTAL       => 31248,
            FREE        => 25123,
            VOLUMN      => 'rpool/export',
            FILESYSTEM  => 'zfs'
        },
        {
            VOLUMN      => 'rpool/export/home',
            TOTAL       => 31248,
            FREE        => 25123,
            TYPE        => '/export/home',
            FILESYSTEM  => 'zfs'
        },
        {
            TYPE        => '/export/home/user',
            VOLUMN      => 'rpool/export/home/user',
            TOTAL       => 31248,
            FREE        => 25123,
            FILESYSTEM  => 'zfs'
        },
        {
            TOTAL       => 31248,
            FREE        => 25123,
            VOLUMN      => 'rpool',
            TYPE        => '/rpool',
            FILESYSTEM  => 'zfs'
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
