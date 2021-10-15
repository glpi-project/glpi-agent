#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;
use XML::TreePP;

use GLPI::Agent::XML::Query::Prolog;

plan tests => 4;

my $message;

throws_ok {
    $message = GLPI::Agent::XML::Query::Prolog->new(
    );
} qr/^no deviceid/, 'no device id';

lives_ok {
    $message = GLPI::Agent::XML::Query::Prolog->new(
        deviceid => 'foo',
    );
} 'everything OK';

isa_ok($message, 'GLPI::Agent::XML::Query::Prolog');

my $tpp = XML::TreePP->new();

cmp_deeply(
    scalar $tpp->parse($message->getContent()),
    {
        REQUEST => {
            DEVICEID => 'foo',
            TOKEN    => '12345678',
            QUERY    => 'PROLOG',
        }
    },
    'expected content'
);
