#!/usr/bin/perl

use strict;
use warnings;

use Compress::Zlib;
use English qw(-no_match_vars);
use Test::More;
use Test::Exception;

use GLPI::Agent::HTTP::Client::OCS;

plan tests => 2;

my $client = GLPI::Agent::HTTP::Client::OCS->new();

my $data = "this is a test";

# Test zlib compression
$client->{compression} = 'zlib';
is(
    $client->uncompress($client->compress($data), 'x-compress-zlib'),
    $data,
    'round-trip compression with zlib compression'
);

SKIP: {
    skip "gzip is not available under Windows", 1 if $OSNAME eq 'MSWin32';
    $client->{compression} = 'gzip';
    is(
        $client->uncompress($client->compress($data), 'x-compress-gzip'),
        $data,
        'round-trip compression with Gzip'
    );
}
