#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use GLPI::Agent::Tools::Network;

my @network_ok_tests = qw(
    10.0.0.0/32
    10.0.0/24
    10.0/16
    10/8
);

my @network_nok_tests = qw(
    10.0.0.0
);

my @hex2canonical_tests = (
    [ 'ffffffff',   '255.255.255.255' ],
    [ '0xffffffff', '255.255.255.255' ],
    [ '7f7f7f7f',   '127.127.127.127' ],
    [ '0x7f7f7f7f', '127.127.127.127' ]
);

my @alt2canonical_tests = (
    [ 'AABBCCDDEEFF', 'AA:BB:CC:DD:EE:FF' ],
    [ '0xAABBCCDDEEFF', 'AA:BB:CC:DD:EE:FF' ],
    [ 'AA:BB:CC:DD:EE:FF', 'AA:BB:CC:DD:EE:FF' ],
    [ 'AA BB CC DD EE FF', 'AA:BB:CC:DD:EE:FF' ],
    [ 'AA-BB-CC-DD-EE-FF', 'AA:BB:CC:DD:EE:FF' ],
);

my @mask_tests = (
    [ '127.0.0.1',   32, '255.255.255.255' ],
    [ '191.168.0.1', 24, '255.255.255.0'   ],
);

my @same_network_ok_tests = (
    [ '192.168.0.1', '192.168.0.254', '255.255.255.0' ],
);

my @same_network_nok_tests = (
    [ '192.168.0.1', '192.168.0.254', '255.255.255.128' ],
);

plan tests =>
    scalar @network_ok_tests    +
    scalar @network_nok_tests   +
    scalar @hex2canonical_tests +
    scalar @alt2canonical_tests +
    scalar @mask_tests          +
    scalar @same_network_ok_tests  +
    scalar @same_network_nok_tests +
    2;

foreach my $test (@network_ok_tests) {
    ok($test =~ $network_pattern, "$test matches network pattern");
}

foreach my $test (@network_nok_tests) {
    ok($test !~ $network_pattern, "$test doesn't match network pattern");
}

foreach my $test (@same_network_ok_tests) {
    ok(isSameNetwork(@$test), "$test->[0] and $test->[1] share same network");
}

foreach my $test (@same_network_nok_tests) {
    ok(!isSameNetwork(@$test), "$test->[0] and $test->[1] don't share same network");
}

foreach my $test (@hex2canonical_tests) {
    is(
        hex2canonical($test->[0]),
        $test->[1],
        "$test->[0] conversion"
    );
}

foreach my $test (@alt2canonical_tests) {
    is(
        alt2canonical($test->[0]),
        $test->[1],
        "$test->[0] conversion"
    );
}

foreach my $test (@mask_tests) {
    is(
        getNetworkMask($test->[1]),
        $test->[2],
        "$test->[0]/$test->[1] mask extraction"
    );
}

SKIP: {
skip 'Author test', 2 unless $ENV{TEST_AUTHOR};

my @localhost_results = resolve("localhost");

ok(
    @localhost_results,
    "Can resolve localhost"
);

my @google_results = resolve("www.google.com");
ok(
    @google_results >= 2,
    "Can resolve www.google.com"
);
}
