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
use Cpanel::JSON::XS;

use GLPI::Agent;
use GLPI::Agent::Config;
use GLPI::Agent::Logger;
use GLPI::Agent::HTTP::Server;
use GLPI::Agent::HTTP::Server::Proxy;
use GLPI::Agent::HTTP::Client::GLPI;
use GLPI::Agent::HTTP::Client::OCS;
use GLPI::Agent::XML::Response;
use GLPI::Agent::Target::Server;
use GLPI::Agent::Protocol::Answer;

plan tests => 55;

my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ]
);

# Override include directive to local dedicated config and avoid loading local one if exists
my $config_module = Test::MockModule->new('GLPI::Agent::Config');
$config_module->mock('_includeDirective', sub {
    my ($self) = @_;
    $self->_loadUserParams({
        disabled    => "no",
    });
});

my $agent = Test::MockObject::Extends->new(GLPI::Agent->new());
my $server = {
    agent   => $agent,
};
# Prohibit agent forking api by mocking its fork related methods
my @events;
$agent->mock( fork   => sub { 0 } );
$agent->mock( forked => sub { 0 } );
$agent->mock( forked_process_event => sub { shift; push @events, shift; } );

# Mock GLPI client
my $client_module = Test::MockModule->new('GLPI::Agent::HTTP::Client::GLPI');
$client_module->mock('send', sub {
    my ($self, %params) = @_;
    my ($test) = $params{url} =~ m/\?test=(.*)$/;
    return if $test && $test eq "noserver";
    return GLPI::Agent::Protocol::Answer->new(
        status      => "ok",
        expiration  => "24",
    );
});

my $ocs_client_module = Test::MockModule->new('GLPI::Agent::HTTP::Client::OCS');
$ocs_client_module->mock('send', sub {
    my ($self, %params) = @_;
    my ($test) = $params{url} =~ m/\?test=(.*)$/;
    return GLPI::Agent::XML::Response->new(
        content => "<REPLY></REPLY>",
    ) if $test && $test eq "sent";;
});

my $proxy;
lives_ok {
    $proxy = GLPI::Agent::HTTP::Server::Proxy->new(
        server  => $server,
    );
} "proxy instanciation";

lives_ok {
    $proxy->init();
} "proxy initialization";

# We don't test maxrate
$proxy->config("maxrate", 0);

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

is( $response->content, $GLPI::Agent::HTTP::Server::Proxy::VERSION, "returned apiversion" );
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
is( $proxy->{requestid}, undef, "wrong request id is unset" );

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
    if ($_[3] && $_[3] eq 'xml') {
        my $resp = GLPI::Agent::XML::Response->new(
            content => $response->content
        );
        my $hash = { REPLY => $resp->getContent() };
        is_deeply($hash, $_[1], "Expected ".($_[2]//$_[1])." error message in response");
    } elsif ($_[3] && $_[3] eq 'json') {
        my $json = Cpanel::JSON::XS->new;
        my $hash = $json->decode($response->content);
        is_deeply($hash, $_[1], "Expected ".($_[2]//$_[1])." error message in response");
    } else {
        is( $response->content, $_[1], "Expected ".($_[2]//$_[1])." error message in response");
    }
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
    check_error(200, { REPLY => { PROLOG_FREQ => "24", RESPONSE => "SEND" } }, "Supported xml PROLOG query", "xml");
};

_request(
    content         => "<?xml version='1.0' encoding='UTF-8' ?><REQUEST><QUERY>INVENTORY</QUERY><DEVICEID>foo</DEVICEID></REQUEST>",
);
subtest "Supported xml INVENTORY query" => sub {
    check_error(200, { REPLY => "" }, "Supported xml INVENTORY query", "xml");
};

# Wrong configuration
$proxy->config("only_local_store", 1);
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
    check_error(200, { REPLY => "" }, "Supported xml INVENTORY query stored", "xml");
};
SKIP: {
    skip ('chmod not working as expected on Win32', 1)
        if ($OSNAME eq 'MSWin32');
    chmod 400, $local_store;
    _request();
    subtest "only only_local_store but can't store" => sub {
        check_error(500, "Proxy cannot store content");
    };
    chmod 755, $local_store;
}

my $glpi = GLPI::Agent::Target::Server->new(
    url         => 'http://glpi-project.test/glpi',
    basevardir  => 'var',
);
$glpi->isGlpiServer(0);
$agent->{targets} = [ $glpi ];
$proxy->config("only_local_store", 0);
_request();
subtest "failing to pass inventory to server" => sub {
    check_error(500, "Inventory not sent to server0");
};

$glpi->{url} = "http://glpi-project.test/glpi?test=sent";
_request();
subtest "send inventory to server" => sub {
    check_error(200, { REPLY => "" }, "Inventory sent to server0", "xml");
};

#
# From here we are testing GLPI Agent protocol
#
$agent->{targets} = [];
$proxy->config("only_local_store", 1);
_request(
    content         => "<?xml version='1.0' encoding='UTF-8' ?><REQUEST><QUERY>TEST</QUERY></REQUEST>",
    "GLPI-Agent-ID" => $agentid
);
subtest "Unsupported xml content with new protocol" => sub {
    check_error(403, "Not a legacy CONTACT");
};

_request(
    content         => "<?xml version='1.0' encoding='UTF-8' ?><REQUEST><QUERY>PROLOG</QUERY></REQUEST>",
);
subtest "Unsupported xml content with new protocol" => sub {
    check_error(403, "No deviceid in CONTACT");
};

_request(
    content         => "<?xml version='1.0' encoding='UTF-8' ?><REQUEST><QUERY>PROLOG</QUERY><DEVICEID>foo</DEVICEID></REQUEST>",
);
subtest "Supported xml PROLOG query" => sub {
    check_error(200, {
        disabled    => [ qw(netdiscovery netinventory esx collect deploy wakeonlan) ],
        expiration  => 24,
        message     => "contact on only storing proxy agent",
        status      => "ok",
        tasks       => {
            inventory   => {}
        }
    }, "Supported xml PROLOG query with JSON answer", "json");
};

# Same request but with a server set
$proxy->config("only_local_store", 0);
$glpi->{url} = "http://glpi-project.test/glpi";
$glpi->isGlpiServer(1);
$agent->{targets} = [ $glpi ];
_request();
subtest "Supported xml PROLOG query with GLPI server" => sub {
    check_error(202, {
        expiration  => '0',
        status      => "pending",
    }, "Supported xml PROLOG query with JSON answer", "json");
};

# json content-type only supported for new protocol with glpi-agent-id header, but not valid
_request(
    content         => compress("{xxx}"),
    "Content-Type"  => "application/x-compress-zlib",
    "GLPI-Agent-ID" => $agentid
);
subtest "Unsupported compressed json content with new protocol" => sub {
    check_error(403, "Unsupported JSON Content");
};

$proxy->config("local_store", $local_store."XXX");
_request(
    content         => compress('{ "action": "contact" }'),
    "Content-Type"  => "application/x-compress-zlib",
    "GLPI-Agent-ID" => $agentid
);
subtest "JSON message but not existing store" => sub {
    check_error(500, 'Proxy local store missing');
};

$proxy->config("local_store", $local_store."XXX");
_request(
    content         => '{ "action": "contact" }',
    "Content-Type"  => "application/json",
    "GLPI-Agent-ID" => $agentid
);
subtest "JSON message but not existing store" => sub {
    check_error(500, 'Proxy local store missing');
};

$proxy->config("local_store", "");
$proxy->config("only_local_store", 1);
_request(
    content         => '{ "action": "inventory" }',
    "Content-Type"  => "application/json",
    "GLPI-Agent-ID" => $agentid
);
subtest "JSON inventory but not existing store" => sub {
    check_error(500, 'Proxy local store not set');
};

$proxy->config("local_store", $local_store);
_request();
subtest "JSON inventory action stored" => sub {
    check_error(200, { status => "ok" }, "JSON inventory action stored", "json");
};

SKIP: {
    skip ('chmod not working as expected on Win32', 1)
        if ($OSNAME eq 'MSWin32');
    chmod 400, $local_store;
    _request();
    subtest "only only_local_store but can't store" => sub {
        check_error(500, "Proxy failed to store datas");
    };
    chmod 755, $local_store;
}

$proxy->config("only_local_store", 0);
$glpi->{url} = "http://glpi-project.test/glpi?test=noserver";
_request();
subtest "JSON inventory pending request but ko" => sub {
    check_error(202, { status => "pending", expiration => "10s" }, "JSON inventory action stored", "json");
};
like(shift @events, qr/^PROXYREQ,[0-9A-F]{8},.*"status":"pending"/, "Pending inventory event");
like(shift @events, qr/^PROXYREQ,[0-9A-F]{8},.*"message":"server0 forward failure"/, "Pending inventory event not sent");

$glpi->{url} = "http://glpi-project.test/glpi?test=sent";
_request();
subtest "JSON inventory pending request and ok" => sub {
    check_error(202, { status => "pending", expiration => "10s" }, "JSON inventory action stored", "json");
};
like(shift @events, qr/^PROXYREQ,[0-9A-F]{8},.*"status":"pending"/, "Pending inventory event");
like(shift @events, qr/^PROXYREQ,[0-9A-F]{8},\d+$/, "Pending inventory timing event");
like(shift @events, qr/^PROXYREQ,[0-9A-F]{8},.*"status":"ok"/, "Pending inventory event sent");
