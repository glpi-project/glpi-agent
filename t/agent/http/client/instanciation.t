#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use GLPI::Agent::HTTP::Client;

plan tests => 3;

my $client;

# instanciations tests

throws_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        config => {
            'ca-cert-file' => '/no/such/file',
        },
    );
} qr/^non-existing certificate file/,
'instanciation: invalid ca cert file';

throws_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        config => {
            'ca-cert-dir' => '/no/such/directory',
        },
    );
} qr/^non-existing certificate directory/,
'instanciation: invalid ca cert directory';

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new();
} 'instanciation: http';
