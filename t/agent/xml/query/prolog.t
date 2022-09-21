#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;

use GLPI::Agent::XML;
use GLPI::Agent::XML::Query::Prolog;

plan tests => 5;

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

my $xml = GLPI::Agent::XML->new(string => $message->getContent());

isa_ok($xml, 'GLPI::Agent::XML');

cmp_deeply(
    $xml->dump_as_hash(),
    {
        REQUEST => {
            DEVICEID => 'foo',
            TOKEN    => '12345678',
            QUERY    => 'PROLOG',
        }
    },
    'expected content'
);
