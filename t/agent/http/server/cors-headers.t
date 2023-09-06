#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use LWP::UserAgent;
use Time::HiRes qw(usleep);
use HTTP::Headers;
use HTTP::Request;
use HTTP::Response;
use File::Temp qw(tempdir);
use Test::More;
use Test::Exception;

use GLPI::Test::Agent;
use GLPI::Agent::HTTP::Server;
use GLPI::Agent::Logger;
use GLPI::Agent::Target::Server;
use GLPI::Test::Utils;

plan skip_all => 'Not working on github action windows image'
    if $OSNAME eq 'MSWin32' && exists($ENV{GITHUB_ACTIONS});

plan tests => 55;

# find an available port
my $port = GLPI::Agent::Tools::first { test_port($_) } 8080 .. 8180;

my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ]
);

my $basevardir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);
my $target = GLPI::Agent::Target::Server->new(
    url        => 'http://127.0.0.1/',
    basevardir => $basevardir
);

my $server;

lives_ok {
    $server = GLPI::Agent::HTTP::Server->new(
        agent     => GLPI::Test::Agent->new(),
        ip        => '127.0.0.1',
        logger    => $logger,
        port      => $port,
        trust     => [ '127.0.0.1' ],
        htmldir   => 'share/html'
    );
} 'instanciation with localhost trusted: ok';

# Add server target to agent as it should be done normally
push @{$server->{agent}->{targets}}, $target;

lives_ok {
    $server->init();
} "server initialization";

ok (
    defined($server->{trust}->{'127.0.0.1'}),
    '127.0.0.1 as trusted address'
);

ok (
    $server->_isTrusted('127.0.0.1'),
    'server trusting 127.0.0.1 address'
);

my ($pid, $request, $response);
my $client = LWP::UserAgent->new(timeout => 2);
my $headers = HTTP::Headers->new();

sub _make_server_request {
    my ($test) = @_;

    # Fork server
    unless ($pid = fork()) {
        my $timeout = time + 10;
        local $SIG{INT} = sub { $timeout = time; };
        while (!$server->handleRequests() && time < $timeout) { usleep 50000; };
        waitpid($pid, 0);
        exit(0);
    }
    # Make request
    lives_ok {
        $response = $client->simple_request($request);
    } $test;
}

# First validate a simple request on index
$request = HTTP::Request->new(GET => "http://127.0.0.1:$port", $headers);
_make_server_request("simple index request");
ok($response->is_success(), "success on simple index request");
ok(!$response->header("Access-Control-Allow-Origin"));
ok(!$response->header('client-warning'), "no client warning on simple index request");
is($response->code(), 200, "returned code on simple index request");

# Test OPTIONS request on /now with wrong method
$headers->header("Access-Control-Request-Method" => "PUT");
$request = HTTP::Request->new(OPTIONS => "http://127.0.0.1:$port/now", $headers);
_make_server_request("wrong method on OPTIONS request");
ok(!$response->is_success(), "denied on wrong OPTIONS method request");
ok(!$response->header('client-warning'), "no client warning on wrong OPTIONS method request");
is($response->code(), 403, "returned code on wrong OPTIONS method request");

# Test OPTIONS request on /now with GET method
$headers->header("Access-Control-Request-Method" => "GET");
$request = HTTP::Request->new(OPTIONS => "http://127.0.0.1:$port/now", $headers);
_make_server_request("expected method on OPTIONS request");
ok($response->is_success(), "success on expected OPTIONS method request");
ok(!$response->header('client-warning'), "no client warning on expected OPTIONS method request");
is($response->code(), 204, "returned code on expected OPTIONS method request");
is($response->header('Access-Control-Request-Method'), "GET", "supported method on expected OPTIONS method request");
ok(!$response->header('Access-Control-Allow-Origin'), "allowed origin not set on expected OPTIONS method request without Origin header");
ok(!$response->header('Access-Control-Allow-Headers'), "allowed headers not set on expected OPTIONS method request without Origin header");

# Test OPTIONS request on /now with GET method & Origin header set
$headers->header("Origin" => "http://127.0.0.1");
$request = HTTP::Request->new(OPTIONS => "http://127.0.0.1:$port/now", $headers);
_make_server_request("expected method on OPTIONS request with Origin");
ok($response->is_success(), "success on expected OPTIONS method request with Origin");
ok(!$response->header('client-warning'), "no client warning on expected OPTIONS method request with Origin");
is($response->code(), 204, "returned code on expected OPTIONS method request with Origin");
is($response->header('Access-Control-Request-Method'), "GET", "supported method on expected OPTIONS method request with Origin");
is($response->header('Access-Control-Allow-Origin'), "http://127.0.0.1", "allowed origin set on expected OPTIONS method request with Origin");
ok(!$response->header('Access-Control-Allow-Headers'), "allowed headers not set on expected OPTIONS method request with Origin");

# Test OPTIONS request on /now with GET method, Origin header & header request set
$headers->header("Access-Control-Request-Headers" => "Content-Type");
$request = HTTP::Request->new(OPTIONS => "http://127.0.0.1:$port/now", $headers);
_make_server_request("expected method on OPTIONS request with Origin & header control");
ok($response->is_success(), "success on expected OPTIONS method request with Origin & header control");
ok(!$response->header('client-warning'), "no client warning on expected OPTIONS method request with Origin & header control");
is($response->code(), 204, "returned code on expected OPTIONS method request with Origin & header control");
is($response->header('Access-Control-Request-Method'), "GET", "supported method on expected OPTIONS method request with Origin & header control");
is($response->header('Access-Control-Allow-Origin'), "http://127.0.0.1", "allowed origin set on expected OPTIONS method request with Origin & header control");
is($response->header('Access-Control-Allow-Headers'), "*", "allowed headers set on expected OPTIONS method request with Origin & header control");

# Test GET request on /now with wrong Origin
$headers->header("Origin" => "http://10.0.0.1");
$headers->remove_header("Access-Control-Request-Method");
$headers->remove_header("Access-Control-Request-Headers");
$request = HTTP::Request->new(GET => "http://127.0.0.1:$port/now", $headers);
_make_server_request("GET request with not expected Origin");
ok(!$response->is_success(), "denied on wrong GET method request");
ok(!$response->header('client-warning'), "no client warning on wrong GET method request");
is($response->code(), 403, "returned code on wrong GET method request");
ok(!$response->header('Access-Control-Request-Method'), "supported method not set on wrong GET method request");
ok(!$response->header('Access-Control-Allow-Origin'), "allowed origin not set on wrong GET method request");
ok(!$response->header('Access-Control-Allow-Headers'), "allowed headers not set on wrong GET method request");

# Test GET request on /now with expected Origin
$headers->header("Origin" => "http://127.0.0.1");
$request = HTTP::Request->new(GET => "http://127.0.0.1:$port/now", $headers);
_make_server_request("GET request with expected Origin");
ok($response->is_success(), "success on GET request with expected Origin");
ok(!$response->header('client-warning'), "no client warning on GET request with expected Origin");
is($response->code(), 200, "returned code on GET request with expected Origin");
ok(!$response->header('Access-Control-Request-Method'), "supported method not set on GET request with expected Origin");
is($response->header('Access-Control-Allow-Origin'), "http://127.0.0.1", "allowed origin set on GET request with expected Origin");
ok(!$response->header('Access-Control-Allow-Headers'), "allowed headers not set on GET request with expected Origin");

# Test GET request on /now with expected Origin & request allow header
$headers->header("Access-Control-Request-Headers" => "Content-Type");
$request = HTTP::Request->new(GET => "http://127.0.0.1:$port/now", $headers);
_make_server_request("GET request with expected Origin & request allow header");
ok($response->is_success(), "success on GET request with expected Origin & request allow header");
ok(!$response->header('client-warning'), "no client warning on GET request with expected Origin & request allow header");
is($response->code(), 200, "returned code on GET request with expected Origin & request allow header");
ok(!$response->header('Access-Control-Request-Method'), "supported method not set on GET request with expected Origin & request allow header");
is($response->header('Access-Control-Allow-Origin'), "http://127.0.0.1", "allowed origin set on GET request with expected Origin & request allow header");
is($response->header('Access-Control-Allow-Headers'), "*", "allowed headers set on expected GET request with expected Origin & request allow header");

END {
    kill "-INT", $pid if $pid;
}
