#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;
use XML::TreePP;

use GLPI::Agent::XML::Query;

plan tests => 7;

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

my $tpp = XML::TreePP->new();

cmp_deeply(
    scalar $tpp->parse($message->getContent()),
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
    scalar $tpp->parse($message->getContent()),
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
