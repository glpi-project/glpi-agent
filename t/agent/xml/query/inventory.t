#!/usr/bin/perl

use strict;
use warnings;

use Config;
use Test::Deep;
use Test::Exception;
use Test::More;
use XML::TreePP;

use GLPI::Agent::Version;
use GLPI::Agent::Inventory;
use GLPI::Agent::XML::Query::Inventory;

plan tests => 5;

my $query;
throws_ok {
    $query = GLPI::Agent::XML::Query::Inventory->new();
} qr/^no content/, 'no content';

my $inventory =  GLPI::Agent::Inventory->new();
lives_ok {
    $query = GLPI::Agent::XML::Query::Inventory->new(
        deviceid => 'foo',
        content  => $inventory->getContent()
    );
} 'everything OK';

isa_ok($query, 'GLPI::Agent::XML::Query::Inventory');

my $tpp = XML::TreePP->new();
my $AgentString = $GLPI::Agent::Version::PROVIDER."-Inventory_v".$GLPI::Agent::Version::VERSION;

cmp_deeply(
    scalar $tpp->parse($query->getContent()),
    {
        REQUEST => {
            DEVICEID => 'foo',
            QUERY    => 'INVENTORY',
            CONTENT  => {
                HARDWARE => {
                    VMSYSTEM => 'Physical'
                },
                VERSIONCLIENT => $AgentString,
            },
        }
    },
    'empty inventory, expected content'
);

$inventory->addEntry(
    section => 'SOFTWARES',
    entry   => {
        NAME => '<&>',
    }
);

$query = GLPI::Agent::XML::Query::Inventory->new(
    deviceid => 'foo',
    content => $inventory->getContent()
);

cmp_deeply(
    scalar $tpp->parse($query->getContent()),
    {
        REQUEST => {
            DEVICEID => 'foo',
            QUERY => 'INVENTORY',
            CONTENT => {
                HARDWARE => {
                    VMSYSTEM => 'Physical'
                },
                VERSIONCLIENT => $AgentString,
                SOFTWARES => {
                    NAME => '<&>'
                }
            },
        }
    },
    'additional content with prohibited characters, expected content'
);
