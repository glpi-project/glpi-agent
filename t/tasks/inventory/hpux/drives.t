#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::HPUX::Drives;

my %tests = (
    'hpux1-nfs' => [
        {
            VOLUMN => 'nfs:/u02/logs/root/kbmon/hpux/dgs/output/ignsrv',
            TOTAL  => '50412224',
            FREE   => '17585104',
            TYPE   => '/net/hpux-dgs-output'
        }

    ],
    'hpux1-vxfs' => [
        {
            VOLUMN => '/dev/vg00/lvol3',
            TOTAL  => '2097152',
            FREE   => '339960',
            TYPE   => '/'
        },
        {
            VOLUMN => '/dev/vg00/lvol1',
            TOTAL  => '1048576',
            FREE   => '206072',
            TYPE   => '/stand'
        },
        {
            VOLUMN => '/dev/vg00/lvol8',
            TOTAL  => '163840000',
            FREE   => '118781336',
            TYPE   => '/var'
        },
        {
            VOLUMN => '/dev/vg00/lvol7',
            TOTAL  => '12320768',
            FREE   => '2624872',
            TYPE   => '/usr'
        },
        {
            VOLUMN => '/dev/vg01/lvol1',
            TOTAL  => '291504128',
            FREE   => '59158883',
            TYPE   => '/u02'
        },
        {
            VOLUMN => '/dev/vg00/lvol6',
            TOTAL  => '10289152',
            FREE   => '2509304',
            TYPE   => '/u01'
        },
        {
            VOLUMN => '/dev/vg00/lvol5',
            TOTAL  => '2097152',
            FREE   => '134312',
            TYPE   => '/tmp'
        },
        {
            VOLUMN => '/dev/vgmsa2/lvol1',
            TOTAL  => '3984588800',
            FREE   => '2791336896',
            TYPE   => '/storage'
        },
        {
            VOLUMN => '/dev/vg00/lvol4',
            TOTAL  => '8388608',
            FREE   => '3475856',
            TYPE   => '/opt'
        },
        {
            VOLUMN => '/dev/vg00/lvol11',
            TOTAL  => '1048576',
            FREE   => '666387',
            TYPE   => '/backup.loc'
        }
    ],
    'hpux2-nfs' => [
        {
            VOLUMN => 'ignsrv:/storage/Archive',
            TOTAL  => '3984588800',
            FREE   => '1184657264',
            TYPE   => '/net/Archive'
        },
        {
            VOLUMN => 'nfs:/u02/logs/root/kbmon/hpux/dgs/output',
            TOTAL  => '50412224',
            FREE   => '17607224',
            TYPE   => '/net/hpux-dgs-chdo'
        }

    ],
    'hpux2-vxfs' => [
        {
            VOLUMN => '/dev/vg00/lvol3',
            TOTAL  => '2097152',
            FREE   => '344480',
            TYPE   => '/'
        },
        {
            VOLUMN => '/dev/vg00/lvol1',
            TOTAL  => '2097152',
            FREE   => '146384',
            TYPE   => '/stand'
        },
        {
            VOLUMN => '/dev/vg00/lvol8',
            TOTAL  => '30736384',
            FREE   => '17318632',
            TYPE   => '/var'
        },
        {
            VOLUMN => '/dev/vg00/lvol7',
            TOTAL  => '12288000',
            FREE   => '2631792',
            TYPE   => '/usr'
        },
        {
            VOLUMN => '/dev/vg01/lvol1',
            TOTAL  => '283115520',
            FREE   => '227557603',
            TYPE   => '/u02'
        },
        {
            VOLUMN => '/dev/vg00/lvol6',
            TOTAL  => '31457280',
            FREE   => '24969328',
            TYPE   => '/u01'
        },
        {
            VOLUMN => '/dev/vg00/lvol5',
            TOTAL  => '8388608',
            FREE   => '6495544',
            TYPE   => '/tmp'
        },
        {
            VOLUMN => '/dev/vg00/lvol4',
            TOTAL  => '12288000',
            FREE   => '3974232',
            TYPE   => '/opt'
        },
        {
            VOLUMN => '/dev/vg00/lvol11',
            TOTAL  => '1048576',
            FREE   => '195605',
            TYPE   => '/backup.loc'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/hpux/bdf/$test";
    my @drives = GLPI::Agent::Task::Inventory::HPUX::Drives::_parseBdf(file => $file);
    cmp_deeply(\@drives, $tests{$test}, "$test bdf parsing");
    lives_ok {
        $inventory->addEntry(section => 'DRIVES', entry => $_) foreach @drives;
    } "$test: registering";
}
