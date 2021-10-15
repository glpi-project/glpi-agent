#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::AIX::Controllers;

my %tests = (
    'aix-5.3a' => [
        {
            NAME => 'ent0',
        },
        {
            NAME => 'ent1',
        },
        {
            NAME => 'ide0',
        },
        {
            NAME => 'lai0',
        },
        {
            NAME => 'sa0',
        },
        {
            NAME => 'sa1',
        },
        {
            NAME => 'sisscsia0',
        },
        {
            NAME => 'usbhc0',
        },
        {
            NAME => 'usbhc1',
        },
        {
            NAME  => 'vsa0',
        },
        {
            NAME => 'vsa1',
        },
        {
            NAME => 'vsa2',
        }
    ],
    'aix-5.3b' => [
        {
            NAME => 'ent0',
        },
        {
            NAME => 'ent1',
        },
        {
            NAME => 'ent2',
        },
        {
            NAME => 'ent3',
        },
        {
            NAME => 'ent4',
        },
        {
            NAME => 'sisioa0',
        },
        {
            NAME => 'usbhc0',
        },
        {
            NAME => 'usbhc1',
        },
        {
            NAME => 'vsa0',
        }
    ],
    'aix-5.3c' => [
        {
            NAME => 'ent0',
        },
        {
            NAME => 'ent1',
        },
        {
            NAME => 'ent2',
        },
        {
            NAME => 'lhea0',
        },
        {
            NAME => 'vsa0',
        },
        {
            NAME => 'vscsi0',
        }
    ],
    'aix-6.1a' => [
        {
            NAME => 'ent0'
        },
        {
            NAME => 'ent1'
        },
        {
            NAME => 'ent2'
        },
        {
            NAME => 'fcs0'
        },
        {
            NAME => 'fcs1'
        },
        {
            NAME => 'fcs2'
        },
        {
            NAME => 'fcs3'
        },
        {
            NAME => 'fcs4'
        },
        {
            NAME => 'lhea0'
        },
        {
            NAME => 'vsa0'
        },
        {
            NAME => 'vscsi0'
        },
        {
            NAME => 'vscsi1'
        }
    ],
    'aix-6.1b' => [
        {
            NAME  => 'ati0'
        },
        {
            NAME  => 'ent0'
        },
        {
            NAME  => 'ent1'
        },
        {
            NAME  => 'ent2'
        },
        {
            NAME  => 'ent3'
        },
        {
            NAME  => 'fcs0'
        },
        {
            NAME  => 'fcs1'
        },
        {
            NAME  => 'lhea0'
        },
        {
            NAME  => 'mptsas0'
        },
        {
            NAME  => 'sissas0'
        },
        {
            NAME  => 'usbhc0'
        },
        {
            NAME  => 'usbhc1'
        },
        {
            NAME  => 'usbhc2'
        },
        {
            NAME  => 'vsa0'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/aix/lsdev/$test-adapter";
    my @controllers = GLPI::Agent::Task::Inventory::AIX::Controllers::_getControllers(file => $file);
    cmp_deeply(\@controllers, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'CONTROLLERS', entry => $_) foreach @controllers;
    } "$test: registering";
}
