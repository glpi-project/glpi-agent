#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use HTTP::Request;
use HTTP::Daemon;
use Test::More;
use Test::Exception;
use Test::MockModule;
use Test::MockObject::Extends;
use Compress::Zlib;
use File::Temp;

use FusionInventory::Agent;
use FusionInventory::Agent::Config;
use FusionInventory::Agent::Logger;
use FusionInventory::Agent::HTTP::Server;
use FusionInventory::Agent::HTTP::Server::Proxy;

plan tests => 37;

my $logger = FusionInventory::Agent::Logger->new(
    logger => [ 'Test' ]
);

# Override include directive to local dedicated config and avoid loading local one if exists
my $config_module = Test::MockModule->new('FusionInventory::Agent::Config');
$config_module->mock('_includeDirective', sub {
    my ($self) = @_;
    $self->_loadUserParams({
        disabled    => "no",
    });
});

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

ok( !$proxy->disabled(), "proxy is enabled" );

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
my $response;
$client->mock(send_response => sub { shift; $response = shift; });
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
    is( $response->code, $_[0], "Expected ".($_[2]//$_[0])." response" );
    is( $response->content, $_[1], "Expected ".($_[2]//$_[1])." error message in response");
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

# Compressed content
_request(
    content         => compress("."),
    "Content-Type"  => "application/x-compress-zlib",
);
subtest "Unsupported uncompressed Content-type" => sub {
    check_error(403, "Unsupported Content-type");
};

# Compressed content-type but not compressed
_request(
    content         => ".",
);
subtest "Unsupported compressed Content-type with bad content" => sub {
    check_error(403, "Unsupported Content-type");
};

# json content-type only supported for new protocol
_request(
    content         => compress("{}"),
);
subtest "Unsupported Content-type with compressed json on legacy protocol" => sub {
    check_error(403, "Unsupported Content-type");
};

# json content-type only supported for new protocol with glpi-agent-id header, but not valid
_request(
    content         => compress("{xxx}"),
    "GLPI-Agent-ID" => $agentid
);
subtest "Unsupported compressed json content with new protocol" => sub {
    check_error(403, "Unsupported Content");
};

# xml failure
_request(
    content         => "<>",
    "Content-Type"  => "application/xml",
    "GLPI-Agent-ID" => "",
);
subtest "Unsupported xml content" => sub {
    check_error(403, "Unsupported content");
};

_request(
    content         => "<?xml",
);
subtest "Unsupported xml content" => sub {
    check_error(403, "Unsupported xml content");
};

_request(
    content         => "<?xml version='1.0' encoding='UTF-8' ?><REQUEST><QUERY>TEST</QUERY></REQUEST>",
);
subtest "Unsupported xml query" => sub {
    check_error(403, "Unsupported query");
};

_request(
    content         => "<?xml version='1.0' encoding='UTF-8' ?><REQUEST><QUERY>PROLOG</QUERY></REQUEST>",
);
subtest "Unsupported xml PROLOG query" => sub {
    check_error(403, "PROLOG query without deviceid");
};

_request(
    content         => "<?xml version='1.0' encoding='UTF-8' ?><REQUEST><QUERY>PROLOG</QUERY><DEVICEID>foo</DEVICEID></REQUEST>",
);
subtest "Supported xml PROLOG query" => sub {
    check_error(200, qq(<?xml version="1.0" encoding="UTF-8" ?>
<REPLY>
  <PROLOG_FREQ>24</PROLOG_FREQ>
  <RESPONSE>SEND</RESPONSE>
</REPLY>
), "Supported xml PROLOG query");
};

_request(
    content         => "<?xml version='1.0' encoding='UTF-8' ?><REQUEST><QUERY>INVENTORY</QUERY><DEVICEID>foo</DEVICEID></REQUEST>",
);
subtest "Supported xml INVENTORY query" => sub {
    check_error(200, qq(<?xml version='1.0' encoding='UTF-8'?>
<REPLY></REPLY>
), "Supported xml INVENTORY query");
};

# Wrong configuration
$proxy->config("only_local_store", "yes");
_request(
    content         => "<?xml version='1.0' encoding='UTF-8' ?><REQUEST><QUERY>INVENTORY</QUERY><DEVICEID>foo</DEVICEID></REQUEST>",
);
subtest "only only_local_store but without folder" => sub {
    check_error(500, "No local storage for inventory");
};

my $local_store = File::Temp->newdir();
$proxy->config("local_store", $local_store);
_request();
subtest "only only_local_store with inventory saved" => sub {
    check_error(200, qq(<?xml version='1.0' encoding='UTF-8'?>
<REPLY></REPLY>
), "Supported xml INVENTORY query stored");
};
chmod 400, $local_store;
_request();
subtest "only only_local_store but can't store" => sub {
    check_error(500, "Proxy cannot store content");
};
