#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;

use GLPI::Agent::XML;
use GLPI::Agent::XML::Query;

plan tests => 8;

my $message;
throws_ok {
    $message = GLPI::Agent::XML::Query->new(
        deviceid => 'foo',
    );
} qr/^no query/, 'no query type';

lives_ok {
    $message = GLPI::Agent::XML::Query->new(
        deviceid => 'foo',
        query    => 'TEST',
        foo      => 'foo',
    );
} 'everything OK';

isa_ok($message, 'GLPI::Agent::XML::Query');

my $xml = GLPI::Agent::XML->new(string => $message->getContent());

isa_ok($xml, 'GLPI::Agent::XML');

cmp_deeply(
    $xml->dump_as_hash(),
    {
        REQUEST => {
            DEVICEID => 'foo',
            FOO      => 'foo',
            QUERY    => 'TEST'
        }
    },
    'expected content'
);

lives_ok {
    $message = GLPI::Agent::XML::Query->new(
        deviceid => 'foo',
        query    => 'TEST',
        foo => 'foo',
        castor => [
            {
                FOO => 'fu',
                FFF => 'GG',
                GF =>  [ { FFFF => 'GG' } ]
            },
            {
                FddF => [ { GG => 'O' } ]
            }
        ]
    );
} 'everything OK';

isa_ok($message, 'GLPI::Agent::XML::Query');

cmp_deeply(
    $xml->string($message->getContent())->dump_as_hash(),
    {
        REQUEST => {
            CASTOR => [
                {
                    FFF => 'GG',
                    FOO => 'fu',
                    GF => { FFFF => 'GG' }
                },
                {
                    FddF => { GG => 'O' }
                }
            ],
            DEVICEID => 'foo',
            FOO => 'foo',
            QUERY => 'TEST'
        }
    },
    'expected content'
);
