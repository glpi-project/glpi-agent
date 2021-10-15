#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::Storages::3ware;

my @cards = (
    {
        id => 'c0',
        model => '9650SE-2LP'
    }
);

my @units = (
    {
        id => 'u0',
        index => 0
    }
);

my @ports = (
    {
        id => 'p0',
    },
    {
        id => 'p1',
    },
);

my @storages = (
    {
        FIRMWARE     => '21.07QR4',
        DISKSIZE     => 70912,
        DESCRIPTION  => 'SATA',
        MANUFACTURER => 'Western Digital',
        SERIALNUMBER => 'WD-WMANS1648590',
        MODEL        => 'WDC WD740ADFD-00NLR4',
        TYPE         => 'disk'
    }
);

plan tests => 6;

my $inventory = GLPI::Test::Inventory->new();

cmp_deeply(
    [
        GLPI::Agent::Task::Inventory::Generic::Storages::3ware::_getCards('resources/generic/tw_cli/cards')
    ],
    [ @cards ],
    'cards extraction'
);

cmp_deeply(
    [
        GLPI::Agent::Task::Inventory::Generic::Storages::3ware::_getUnits(
            { id => 'c0' },
            'resources/generic/tw_cli/units'
        )
    ],
    [ @units ],
    'units extraction'
);

cmp_deeply(
    [ GLPI::Agent::Task::Inventory::Generic::Storages::3ware::_getPorts(
            { id => 'c0' },
            { id => 'u0' },
            'resources/generic/tw_cli/ports'
        )
    ],
    [ @ports ],
    'ports extraction'
);

cmp_deeply(
    [
        GLPI::Agent::Task::Inventory::Generic::Storages::3ware::_getStorage(
            { id => 'c0', model => '9650SE-2LP' },
            { id => 'p0' },
            'resources/generic/tw_cli/storage'
        )
    ],
    [ @storages ],
    'storages extraction'
);

lives_ok {
    $inventory->addEntry(section => 'STORAGES', entry => $_)
        foreach @storages;
} "registering";
