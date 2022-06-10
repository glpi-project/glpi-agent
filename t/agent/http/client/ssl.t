#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use Test::Exception;

use GLPI::Agent::Logger;
use GLPI::Agent::HTTP::Client;
use GLPI::Test::Proxy;
use GLPI::Test::Server;
use GLPI::Test::Utils;

use Net::HTTPS;

# Can help to debug SSL negociation in case of failure
#$Net::SSLeay::trace = 1;

unsetProxyEnvVar();

# find an available port
my $port = GLPI::Agent::Tools::first { test_port($_) } 8080 .. 8180;

if (!$port) {
    plan skip_all => 'no available port';
} elsif ($OSNAME eq 'MSWin32') {
    plan skip_all => 'non working test on Windows';
} elsif ($OSNAME eq 'darwin') {
    plan skip_all => 'non working test on MacOS';
} elsif ($LWP::VERSION < 6) {
    plan skip_all => "LWP version too old, skipping";
} else {
    plan tests => 11;
}

diag("LWP\@$LWP::VERSION / LWP::Protocol\@$LWP::Protocol::VERSION / ",
    "IO::Socket\@$IO::Socket::VERSION / IO::Socket::SSL\@$IO::Socket::SSL::VERSION / ",
    "IO::Socket::INET\@$IO::Socket::INET::VERSION / ",
    "Net::SSLeay\@$Net::SSLeay::VERSION / Net::HTTPS\@$Net::HTTPS::VERSION / ",
    "HTTP::Status\@$HTTP::Status::VERSION / HTTP::Response\@$HTTP::Response::VERSION");

my $ok = sub {
    my ($server, $cgi) = @_;

    print "HTTP/1.0 200 OK\r\n";
    print "\r\n";
    print "OK";
};

my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ]
);

unless (-e "resources/ssl/crt/ca.pem") {
    print STDERR "Generating SSL certificates...\n";
    qx(cd resources/ssl ; ./generate.sh );
}

my $proxy = GLPI::Test::Proxy->new();
$proxy->background();

my $server;
my $request;
my $url = "https://127.0.0.1:$port/public";
my $unsafe_client = GLPI::Agent::HTTP::Client->new(
    logger  => $logger,
    config  => {
        'no-ssl-check' => 1,
    },
);

my $secure_client = GLPI::Agent::HTTP::Client->new(
    logger  => $logger,
    config  => {
        'ca-cert-file' => 'resources/ssl/crt/ca.pem',
    },
);

my $secure_proxy_client = GLPI::Agent::HTTP::Client->new(
    logger => $logger,
    config => {
        proxy           => $proxy->url(),
        'ca-cert-file'  => 'resources/ssl/crt/ca.pem',
    },
);

# ensure the server get stopped even if an exception is thrown
$SIG{__DIE__}  = sub { $server->stop(); };

# trusted certificate, correct hostname
$server = GLPI::Test::Server->new(
    port     => $port,
    ssl      => 1,
    crt      => 'resources/ssl/crt/good.pem',
    key      => 'resources/ssl/key/good.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
});

ok($server->background(), "server using a trusted certificat a with correct subject launched in background");

$request = $secure_client->request(HTTP::Request->new(GET => $url));
ok(
    $request->is_success(),
    'connection success with certificate validation'
);

SKIP: {
skip "Known to fail, see: http://forge.fusioninventory.org/issues/1940", 1 unless $ENV{TEST_AUTHOR};
$request = $secure_proxy_client->request(HTTP::Request->new(GET => $url));
ok(
    $request->is_success(),
    'connection success through prox with certificate validation'
);
}

$server->stop();
$proxy->stop();

# trusted certificate, alternate hostname
$server = GLPI::Test::Server->new(
    port     => $port,
    ssl      => 1,
    crt      => 'resources/ssl/crt/alternate.pem',
    key      => 'resources/ssl/key/alternate.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
});
ok($server->background(), "Server using a trusted certificate with a correct alternative name launched in background");

$request = $secure_client->request(HTTP::Request->new(GET => $url));
ok(
    $request->is_success(),
    'connection success with certificate validation'
);

$server->stop();

# trusted certificate, wrong hostname
$server = GLPI::Test::Server->new(
    port     => $port,
    ssl      => 1,
    crt      => 'resources/ssl/crt/wrong.pem',
    key      => 'resources/ssl/key/wrong.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
});
ok($server->background(), "Server using a trusted certificate with an incorrect subject launched in background");

$request = $unsafe_client->request(HTTP::Request->new(GET => $url));
ok(
    $request->is_success(),
    'connection success without certificate validation'
);

$request = $secure_client->request(HTTP::Request->new(GET => $url));
ok(
    !$request->is_success(),
    'connection failure with certificate validation'
);

$server->stop();

# untrusted certificate, correct hostname
$server = GLPI::Test::Server->new(
    port     => $port,
    ssl      => 1,
    crt      => 'resources/ssl/crt/bad.pem',
    key      => 'resources/ssl/key/bad.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
});
ok($server->background(), "Server using an untrusted certificate with an correct subject launched in background");

$request = $unsafe_client->request(HTTP::Request->new(GET => $url));
ok(
    $request->is_success(),
    'connection success without certificate validation'
);

$request = $secure_client->request(HTTP::Request->new(GET => $url));
ok(
    !$request->is_success(),
    'connection failure with certificate validation'
);

$server->stop();
