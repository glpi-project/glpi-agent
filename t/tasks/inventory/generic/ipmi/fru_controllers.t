#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use Data::Dumper;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::Ipmi::Fru::Controllers;

my %tests = (
    'dell-r630' => [
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '0GDJ3J',
            'NAME'         => 'Dell Storage Cntlr. H330 Mini-',
            'REV'          => 'A03',
            'SERIAL'       => 'CN7792169T02BB',
            'TYPE'         => 'PERC'
        },
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '0MG81C',
            'NAME'         => 'DRIVE BACKPLANE',
            'REV'          => 'A02',
            'SERIAL'       => 'CNIVC007CD4368',
            'TYPE'         => 'BP',
        },
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '0G8RPD',
            'NAME'         => 'BRCM 10G/GbE 2+2P 57800-t rNDC',
            'REV'          => 'A00',
            'SERIAL'       => 'CN7543546H00HB',
            'TYPE'         => 'NDC'
        }
    ],
    'dell-r640' => [
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '0PGJ4P',
            'NAME'         => 'DRIVE BACKPLANE',
            'REV'          => 'A00',
            'SERIAL'       => 'CNIVC009C10097',
            'TYPE'         => 'BP',
        },
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '00878M',
            'NAME'         => 'Dell Storage Cntlr. H740P - Mini',
            'REV'          => 'A03',
            'SERIAL'       => 'CNFCP0005M01NC',
            'TYPE'         => 'PERC',
        },
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '01224N',
            'NAME'         => 'BRCM 2P 1G BT + 2P 10G BT rNDC',
            'REV'          => 'A06',
            'SERIAL'       => 'VNFCVBA02O00AZ',
            'TYPE'         => 'NDC',
        }
    ],
    'dell-r720' => [
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '00JDG3',
            'NAME'         => 'DRIVE BACKPLANE',
            'REV'          => 'A00',
            'SERIAL'       => 'CN7543547100IK',
            'TYPE'         => 'BP',
        },
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '0TY8F9',
            'NAME'         => 'Dell Storage Cntlr. H710P-Mini',
            'REV'          => 'A03',
            'SERIAL'       => 'CN7792147F03B1',
            'TYPE'         => 'PERC',
        },
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '0PGXHP',
            'NAME'         => 'DRIVE BACKPLANE',
            'REV'          => 'A02',
            'SERIAL'       => 'CN7792146F02MU',
            'TYPE'         => 'BP',
        },
        {
            'MANUFACTURER' => 'Dell',
            'MODEL'        => '0FM487',
            'NAME'         => 'BRCM GbE 4P 5720-t rNDC',
            'REV'          => 'A03',
            'SERIAL'       => 'CN7543545U06YB',
            'TYPE'         => 'NDC',
        }
    ],
    'hp-dl360-gen7' => [],
    'hp-dl360-gen8' => [
        {
            'SERIAL'       => '001438020C8EF10',
            'NAME'         => 'Smart Array P420i Controller',
            'REV'          => 'B',
            'TYPE'         => 'SAS Ctlr'
        },
        {
            'MODEL'        => '634025-001',
            'SERIAL'       => 'CN82150W2G',
            'NAME'         => 'HP Ethernet 1Gb 4-port 331FLR Adapter',
            'REV'          => '00',
            'TYPE'         => 'Ethernet Adptr',
            'MANUFACTURER' => 'Hewlett-Packard'
        }
    ],
);

plan tests => 2 * (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/generic/ipmitool/fru/$test";
    my $inventory = GLPI::Test::Inventory->new();

    lives_ok {
        GLPI::Agent::Task::Inventory::Generic::Ipmi::Fru::Controllers::doInventory(
            inventory => $inventory,
            file      => $file
        );
    } "test $test: doInventory()";

    my $ctrl = $inventory->getSection('CONTROLLERS') || [];

    cmp_bag(
        $ctrl,
        $tests{$test},
        "test $test: section"
    );
}
