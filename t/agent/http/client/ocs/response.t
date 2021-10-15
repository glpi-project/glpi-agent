#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Compress::Zlib;
use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::More;

use GLPI::Agent::Logger;
use GLPI::Agent::HTTP::Client::OCS;
use GLPI::Agent::XML::Query;
use GLPI::Test::Server;
use GLPI::Test::Utils;

unsetProxyEnvVar();

# find an available port
my $port = GLPI::Agent::Tools::first { test_port($_) } 8080 .. 8180;

if (!$port) {
    plan skip_all => 'no available port';
} else {
    plan tests => 7;
}

my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ]
);

my $message = GLPI::Agent::XML::Query->new(
    deviceid => 'foo',
    query => 'foo',
    msg => {
        foo => 'foo',
        bar => 'bar'
    },
);

my $client = GLPI::Agent::HTTP::Client::OCS->new(
    logger => $logger
);

# http connection tests
my ($server, $response);

$server = GLPI::Test::Server->new(
    port => $port,
);
my $header  = "HTTP/1.0 200 OK\r\n\r\n";
my $xml_content  = "<REPLY><word>hello</word></REPLY>";
my $html_content = "<html><body>hello</body></html>";
$server->set_dispatch({
    '/error'        => sub { print "HTTP/1.0 403 NOK\r\n\r\n"; },
    '/empty'        => sub { print $header; },
    '/uncompressed' => sub { print $header . $html_content; },
    '/mixedhtml'   => sub { print $header . $html_content." a aee".$xml_content ; },
    '/unexpected'   => sub { print $header . compress($html_content); },
    '/correct'      => sub { print $header . compress($xml_content); },
    '/altered'      => sub { print $header . "\n" . compress($xml_content); },
});
$server->background() or BAIL_OUT("can't launch the server");

subtest "error response" => sub {
    check_response_nok(
        scalar $client->send(
            message => $message,
            url     => "http://127.0.0.1:$port/error",
        ),
        $logger,
        "[http client] communication error: 403 NOK",
    );
};

subtest "empty content" => sub {
    check_response_nok(
        scalar $client->send(
            message => $message,
            url     => "http://127.0.0.1:$port/empty",
        ),
        $logger,
        "[http client] unknown content format",
    );
};


subtest "mixedhtml content" => sub {
    check_response_ok(
        scalar $client->send(
            message => $message,
            url     => "http://127.0.0.1:$port/mixedhtml",
        ),
    );
};


subtest "uncompressed content" => sub {
    check_response_nok(
        scalar $client->send(
            message => $message,
            url     => "http://127.0.0.1:$port/uncompressed",
        ),
        $logger,
        "[http client] unexpected content, starting with: $html_content",
    );
};

subtest "unexpected content" => sub {
    check_response_nok(
        scalar $client->send(
            message => $message,
            url     => "http://127.0.0.1:$port/unexpected",
        ),
        $logger,
        "[http client] unexpected content, starting with: $html_content",
    );
};

subtest "correct response" => sub {
    check_response_ok(
        scalar $client->send(
            message => $message,
            url     => "http://127.0.0.1:$port/correct",
        ),
    );
};

subtest "altered response" => sub {
    check_response_ok(
        scalar $client->send(
            message => $message,
            url     => "http://127.0.0.1:$port/altered",
        ),
    );
};

$server->stop();

sub check_response_ok {
    my ($response) = @_;

    plan tests => 3;
    ok(defined $response, "response from server");
    isa_ok(
        $response,
        'GLPI::Agent::XML::Response',
        'response class'
    );
    my $content = $response->getContent();
    cmp_deeply(
        $content,
        { word => 'hello' },
        'response content'
    );
}

sub check_response_nok {
    my ($response, $logger, $message) = @_;

    plan tests => 3;
    ok(!defined $response,  "no response");
    is(
        $logger->{backends}->[0]->{level},
        'error',
        "error message level"
    );
    if (ref $message eq 'Regexp') {
        like(
            $logger->{backends}->[0]->{message},
            $message,
            "error message content"
        );
    } else {
        is(
            $logger->{backends}->[0]->{message},
            $message,
            "error message content"
        );
    }
}
