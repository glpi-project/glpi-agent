#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use HTTP::Request;
use HTTP::Daemon;
use Test::More;
use Test::Exception;
#~ use Test::MockModule;
use Test::MockObject::Extends;

use FusionInventory::Agent;
use FusionInventory::Agent::Logger;
#~ use FusionInventory::Agent::HTTP::Client;
use FusionInventory::Agent::HTTP::Server;
use FusionInventory::Agent::HTTP::Server::Proxy;

use Data::Dumper;

plan tests => 23;

my $logger = FusionInventory::Agent::Logger->new(
    logger => [ 'Test' ]
);

my $agent = Test::MockObject::Extends->new(FusionInventory::Agent->new());
my $server = {
    agent   => $agent,
};
# Prohibit agent forking api by mocking its fork related methods
$agent->mock( fork   => sub { 0 } );
$agent->mock( forked => sub { 0 } );

my $proxy;
lives_ok {
    $proxy = FusionInventory::Agent::HTTP::Server::Proxy->new(
        server  => $server,
    );
} "proxy instanciation";

lives_ok {
    $proxy->init();
} "proxy initialization";

#~ print STDERR Dumper($proxy);

### URL Matching
ok( $proxy->urlMatch("/proxy/apiversion"), "match API version API url" );
ok( $proxy->urlMatch("/proxy/glpi"), "match proxy base url" );
ok( !$proxy->urlMatch("/glpi"), "no match on other url" );

### Supported method
ok( $proxy->supported_method("GET"), "GET method support" );
ok( $proxy->supported_method("POST"), "POST method support" );
ok( !$proxy->supported_method("HEAD"), "HEAD method not supported" );

### GET /proxy/apiversion
my $ip = '127.0.0.1';
my $request = HTTP::Request->new(GET => "/proxy/apiversion");
$proxy->urlMatch($request->uri);
my $client = Test::MockObject::Extends->new(HTTP::Daemon::ClientConn->new());
my ($response, $error);
$client->mock(send_response => sub { shift; $response = shift; });
$client->mock(send_error    => sub { shift; $response = shift; $error = shift; });
lives_ok {
    $proxy->handle($client, $request, $ip);
} "handle GET apiversion";

is( $response->content, $FusionInventory::Agent::HTTP::Server::Proxy::VERSION, "returned apiversion" );
is( $response->status_line, "200 OK", "GET apiversion status" );

sub _request {
    if ($_[0] && $_[0] =~ /^GET|POST$/) {
        my $method = shift;
        my $url = shift;
        $request = HTTP::Request->new($method => $url);
    }
    if ($_[0] && $_[0] =~ /^content$/) {
        shift;
        $request->content(shift);
    }
    $request->header(@_) if @_;
    $proxy->urlMatch($request->uri);
    $proxy->handle($client, $request, $ip);
}

### GLPI-Request-ID header
is( $proxy->{requestid}, undef, "request id is not set" );
_request( "GLPI-Request-ID" => "1234ABCD" );
is( $proxy->{requestid}, "1234ABCD", "request id is set" );
_request( "GLPI-Request-ID" => "zz45TH7812xx" );
is( $proxy->{requestid}, undef, "wrong request is is unset" );

### GLPI-Proxy-ID errors
_request(
    POST            => "/proxy/glpi",
    "GLPI-Proxy-ID" => "a,b,c,d,e,f,g,h"
);
is( $response->status_line, "403 LIMITED-PROXY", "limited proxy error" );
my $agentid = $agent->{agentid} = "880b32f7-44ac-4688-a3e5-00a7665f66fc";
_request( "GLPI-Proxy-ID" => $agentid );
is( $response->status_line, "404 PROXY-LOOP-DETECTED", "proxy loop error" );
_request( "GLPI-Proxy-ID" => "1,2,$agentid,4" );
is( $response->status_line, "404 PROXY-LOOP-DETECTED", "proxy loop error (2)" );

sub check_error {
    is( $response, $_[0], "Expected $_[0] response" );
    is( $error, $_[1], "Expected $_[1] error message in response");
}

## GLPI-Request-ID errors
_request(
    GET                 => "/proxy/glpi",
    "GLPI-Request-ID"   => "1234ABCD"
);
subtest "unknown requestid" => sub {
    check_error(404, "Unknown status" );
};

# Wrong param
_request( GET => "/proxy/glpi?wrongparameter=yes" );
subtest "Unsupported request" => sub {
    check_error(403, "Unsupported request");
};

# Missing Content-Type
_request( POST => "/proxy/glpi" );
subtest "Content-type not set" => sub {
    check_error(403, "Content-type not set" );
};
_request( "Content-Type" => "text/plain" );
subtest "No content" => sub {
    check_error(403, "No content");
};

# server config missing
my $serverconfig = delete $agent->{config};
_request( content => "." );
subtest "Server configuration missing" => sub {
    check_error(500, "Server configuration missing");
};
$agent->{config} = $serverconfig;

# Unsupported legacy content
_request();
subtest "Unsupported Content-type" => sub {
    check_error(403, "Unsupported Content-type");
};
