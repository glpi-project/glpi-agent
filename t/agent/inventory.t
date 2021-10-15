#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Config;
use Test::Deep;
use Test::Exception;
use Test::More;

use GLPI::Agent;
use GLPI::Agent::Logger;
use GLPI::Agent::Inventory;

plan tests => 20;

my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ],
    debug  => 1
);

my $inventory;

lives_ok {
    $inventory = GLPI::Agent::Inventory->new(
        logger => $logger
    );
} 'everything OK';

isa_ok($inventory, 'GLPI::Agent::Inventory');

cmp_deeply(
    $inventory->{content},
    {
        HARDWARE => {
            VMSYSTEM => 'Physical'
        },
        VERSIONCLIENT => $GLPI::Agent::AGENT_STRING
    },
    'initial state'
);

throws_ok {
    $inventory->addEntry(
        section => 'FOOS',
    );
} qr/^no entry/, 'no entry';

throws_ok {
    $inventory->addEntry(
        section => 'FOOS',
        entry   => { bar => 1 }
    );
} qr/^unknown section FOOS/, 'unknown section';

$inventory->addEntry(
    section => 'ENVS',
    entry   => {
        KEY => 'key1',
        VAL => 'val1'
    }
);

my $content;

cmp_deeply(
    $inventory->{content}->{ENVS},
    [
        { KEY => 'key1', VAL => 'val1' }
    ],
    'first environment variable added'
);

$inventory->addEntry(
    section => 'ENVS',
    entry   => {
        KEY => 'key2',
        VAL => 'val2'
    }
);

cmp_deeply(
    $inventory->{content}->{ENVS},
    [
        { KEY => 'key1', VAL => 'val1' },
        { KEY => 'key2', VAL => 'val2' },
    ],
    'second environment variable added'
);

$inventory->addEntry(
    section => 'ENVS',
    entry   => {
        KEY => 'key3',
        VAL => undef
    }
);

cmp_deeply(
    $inventory->{content}->{ENVS},
    [
        { KEY => 'key1', VAL => 'val1' },
        { KEY => 'key2', VAL => 'val2' },
        { KEY => 'key3'                },
    ],
    'entry with undefined value added'
);

$inventory->addEntry(
    section => 'ENVS',
    entry   => {
        KEY => 'key4',
        VAL => "val4\x12"
    }
);

cmp_deeply(
    $inventory->{content}->{ENVS},
    [
        { KEY => 'key1', VAL => 'val1' },
        { KEY => 'key2', VAL => 'val2' },
        { KEY => 'key3'                },
        { KEY => 'key4', VAL => 'val4' }
    ],
    'entry with non-sanitized value added'
);

$inventory->addEntry(
    section => 'ENVS',
    entry   => {
        KEY => 'key5',
        LAV => 'val5'
    }
);

cmp_deeply(
    $inventory->{content}->{ENVS},
    [
        { KEY => 'key1', VAL => 'val1' },
        { KEY => 'key2', VAL => 'val2' },
        { KEY => 'key3'                },
        { KEY => 'key4', VAL => 'val4' },
        { KEY => 'key5'                }
    ],
    'entry with unknown field added'
);

is(
    $logger->{backends}->[0]->{message},
    "unknown field LAV for section ENVS",
    'unknown field logged'
);


$inventory->addEntry(
    section => 'CPUS',
    entry   => {
        NAME         => 'void CPU',
        SPEED        => 1456,
        MANUFACTURER => 'GLPI Developers',
        SERIAL       => 'AEZVRV',
        THREAD       => 3,
        CORE         => 1
    }
);

cmp_deeply(
    $inventory->{content}->{CPUS},
    [
        {
            CORE         => 1,
            MANUFACTURER => 'GLPI Developers',
            NAME         => 'void CPU',
            SERIAL       => 'AEZVRV',
            SPEED        => 1456,
            THREAD       => 3,
        },
    ],
    'CPU added'
);

$inventory->addEntry(
    section => 'DRIVES',
    entry   => {
        FILESYSTEM => 'ext3',
        FREE       => 9120,
        SERIAL     => '7f8d8f98-15d7-4bdb-b402-46cbed25432b',
        TOTAL      => 18777,
        TYPE       => '/',
        VOLUMN     => '/dev/sda2',
    }
);

cmp_deeply(
    $inventory->{content}->{DRIVES},
    [
        {
            FILESYSTEM => 'ext3',
            FREE       => 9120,
            SERIAL     => '7f8d8f98-15d7-4bdb-b402-46cbed25432b',
            TOTAL      => 18777,
            TYPE       => '/',
            VOLUMN     => '/dev/sda2'
        }
    ],
    'drive addition'
);

$inventory->addEntry(
    section => 'STORAGES',
    entry => {
        INTERFACE => 'foo',
        SERIAL    => 'bar'
    }
);

is(
    $logger->{backends}->[0]->{message},
    "invalid value foo for field INTERFACE for section STORAGES",
    'invalid value logged'
);

cmp_deeply(
    $inventory->{content}->{STORAGES},
    [
        {
            INTERFACE    => 'foo',
            SERIAL       => 'bar',
            SERIALNUMBER => 'bar'
        }
    ],
    'drive addition'
);

$inventory->mergeContent(
    {
        SOFTWARES   => [
            {
                NAME => 'foo',
                VERSION => 42,
            },
            {
                NAME => 'bar',
                VERSION => 42,
            }
        ],
        STORAGES   => [
            {
                INTERFACE    => 'oof',
                SERIAL       => 'rab',
            }
        ],
        HARDWARE => {
            UUID => 'd0077ac7-e1e0-49b0-b4a3-475e6e6d417c'
        },
        OPERATINGSYSTEM => {
            FULL_NAME => 'fake fullname',
            NOT_SUPPORTED_FIELD => 0
        },
    }
);

cmp_deeply(
    $inventory->{content}->{SOFTWARES},
    [
        {
            NAME    => 'foo',
            VERSION => 42
        },
        {
            NAME    => 'bar',
            VERSION => 42
        }
    ],
    'empty list section merge'
);

cmp_deeply(
    $inventory->{content}->{STORAGES},
    [
        {
            INTERFACE    => 'foo',
            SERIAL       => 'bar',
            SERIALNUMBER => 'bar'
        },
        {
            INTERFACE    => 'oof',
            SERIAL       => 'rab',
            SERIALNUMBER => 'rab'
        },

    ],
    'non-empty list section merge'
);

is(
    $inventory->{content}->{HARDWARE}->{UUID},
    'd0077ac7-e1e0-49b0-b4a3-475e6e6d417c',
    'hash section merge'
);

is(
    $inventory->{content}->{OPERATINGSYSTEM}->{FULL_NAME},
    'fake fullname',
    'operatingsystem section merge'
);

is(
    $inventory->{content}->{OPERATINGSYSTEM}->{NOT_SUPPORTED_FIELD},
    undef,
    'operatingsystem section merge not supported field'
);
