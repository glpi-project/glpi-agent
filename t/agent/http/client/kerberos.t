#!/usr/bin/perl

# End-to-end test of kerberos authentication in GLPI::Agent::HTTP::Client
#
# A throwaway MIT Kerberos KDC is started by GLPI::Test::Kerberos and a test
# HTTP server emulates the WinRM service authentication: it answers 401 with
# "WWW-Authenticate: Negotiate", accepts the agent token with GSSAPI and the
# service keytab and returns its mutual authentication token. Nothing is
# mocked.
#
# This test is skipped if GSSAPI perl module or MIT Kerberos KDC tools are not
# installed. On Debian/Ubuntu: apt install libgssapi-perl krb5-kdc krb5-admin-server krb5-user

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use HTTP::Request;
use MIME::Base64;
use Test::More;

use GLPI::Agent::Logger;
use GLPI::Agent::HTTP::Client;
use GLPI::Agent::HTTP::Kerberos;
use GLPI::Agent::Tools;
use GLPI::Test::Kerberos;
use GLPI::Test::Server;
use GLPI::Test::Utils;

unsetProxyEnvVar();

my $unavailable = GLPI::Test::Kerberos->unavailable();
plan skip_all => "Kerberos test realm: $unavailable" if $unavailable;

my $port = first { test_port($_) } 8080 .. 8180;
plan skip_all => 'no port available' unless $port;

# Server is reached as localhost, so the agent asks a ticket for HTTP/localhost
my $realm = GLPI::Test::Kerberos->new(
    services => [ 'HTTP/localhost' ],
);

plan tests => 15;

# Kerberos environment set up for the test realm, the https test server resets
# the environment before calling request handlers
my %krb5_env = map { $_ => $ENV{$_} } grep { /^KRB5/ } keys(%ENV);

sub _negotiate {
    my (%params) = @_;
    return sub {
        my ($server, $cgi) = @_;

        my $authorization = delete $ENV{HTTP_AUTHORIZATION} // '';
        local @ENV{keys(%krb5_env)} = values(%krb5_env);
        my ($client, $mutual) = $authorization =~ /^Negotiate\s+(\S+)/ ?
            GLPI::Test::Kerberos::accept_token($1, binding => $params{binding}, strict => $params{strict}) : ();

        # Emulate an authenticated account not allowed to use the service
        undef $client if $params{refuse};

        if ($client) {
            $mutual = 'Zm9yZ2VkIHRva2Vu' if $params{forge};
            print "HTTP/1.0 200 OK\r\n";
            print "WWW-Authenticate: Negotiate $mutual\r\n" unless $params{no_mutual};
            print "Content-Type: text/plain\r\n\r\n";
            print "authenticated as $client";
            # Echo request body like a SOAP answer would depend on it
            my $body = $cgi->param('POSTDATA');
            print ": $body" if defined($body) && length($body);
        } else {
            print "HTTP/1.0 401 Unauthorized\r\n";
            print "WWW-Authenticate: Negotiate\r\n" unless $params{basic_only};
            print "WWW-Authenticate: Basic realm=\"WSMAN\"\r\n";
            print "Content-Type: text/plain\r\n\r\n";
            print "Authentication required";
        }
    };
}

my $server = GLPI::Test::Server->new(port => $port);
$server->set_dispatch({
    '/wsman'        => _negotiate(),
    '/forged'       => _negotiate(forge => 1),
    '/nomutual'     => _negotiate(no_mutual => 1),
    '/basic'        => _negotiate(basic_only => 1),
    '/refused'      => _negotiate(refuse => 1),
    '/strict'       => _negotiate(binding => "tls-server-end-point:unused", strict => 1),
});

# ensure the server and the KDC get stopped even if an exception is thrown, but
# ignore exceptions caught in eval like LWP trying to load LWP::Authen::Negotiate
$SIG{__DIE__} = sub { return if $^S; $server->stop(); $realm->stop(); };

$server->background();

my $logger = GLPI::Agent::Logger->new(
    logger  => [ 'Test' ],
    debug   => 2,
);

sub _client {
    my (%params) = @_;
    return GLPI::Agent::HTTP::Client->new(
        logger      => $logger,
        kerberos    => 1,
        no_ssl_check=> $params{no_ssl_check},
        user        => $params{user},
        password    => $params{password},
    );
}

sub _request {
    my ($path, %params) = @_;
    my $client = $params{client} // _client(%params);
    my $url = ($params{scheme} // "http")."://localhost:$port$path";
    my $request = defined($params{body}) ?
        HTTP::Request->new(POST => $url, [ 'Content-Type' => 'application/soap+xml' ], $params{body}) :
        HTTP::Request->new(GET => $url);
    return $client->request($request);
}

subtest "authenticated with ticket from credentials cache" => sub {
    plan tests => 3;
    my $response = _request('/wsman');
    ok($response->is_success(), "response is success");
    is($response->content(), "authenticated as ".$realm->client(), "server authenticated agent");
    like($logger->{backends}->[0]->{message}, qr/kerberos mutual authentication verified/, "server identity verified");
};

subtest "forged mutual authentication token" => sub {
    plan tests => 2;
    my $response = _request('/forged');
    is($response->code(), 401, "server answer not trusted");
    like($logger->{backends}->[0]->{message}, qr/kerberos mutual authentication failed/, "error logged");
};

subtest "no mutual authentication token" => sub {
    plan tests => 2;
    # Any server could skip mutual authentication if a missing token was accepted
    my $response = _request('/nomutual');
    is($response->code(), 401, "server answer not trusted");
    like($logger->{backends}->[0]->{message}, qr/kerberos mutual authentication failed for HTTP\/localhost: no token provided by server/, "error logged");
};

subtest "negotiate not offered" => sub {
    plan tests => 2;
    my $response = _request('/basic');
    is($response->code(), 401, "response is 401");
    like($logger->{backends}->[0]->{message}, qr/kerberos authentication not offered by server/, "error logged");
};

subtest "no ticket available" => sub {
    plan tests => 2;
    local $ENV{KRB5CCNAME} = 'FILE:'.$realm->file('missing.ccache');
    my $response = _request('/wsman');
    is($response->code(), 401, "response is 401");
    like($logger->{backends}->[0]->{message}, qr{failed to get kerberos token for HTTP/localhost}, "error logged");
};

subtest "several SOAP requests with the same client" => sub {
    plan tests => 3;
    # Like a WinRM remote inventory, each request is authenticated
    my $client = _client();
    foreach my $index (1..3) {
        my $response = _request('/wsman', client => $client, body => "<request>$index</request>");
        is($response->content(), "authenticated as ".$realm->client().": <request>$index</request>", "request $index authenticated with its body");
    }
};

subtest "same client authenticated again when a ticket is available" => sub {
    plan tests => 2;
    my $client = _client();
    {
        local $ENV{KRB5CCNAME} = 'FILE:'.$realm->file('missing.ccache');
        is(_request('/wsman', client => $client)->code(), 401, "no ticket: response is 401");
    }
    ok(_request('/wsman', client => $client)->is_success(), "ticket available: response is success");
};

subtest "kerberos preferred to basic even with credentials" => sub {
    plan tests => 2;
    my $response = _request('/wsman', user => "user", password => "password");
    ok($response->is_success(), "response is success");
    is($response->content(), "authenticated as ".$realm->client(), "authenticated with kerberos");
};

subtest "kerberos authentication refused" => sub {
    plan tests => 2;
    my $response = _request('/refused');
    is($response->code(), 401, "response is 401");
    like($logger->{backends}->[0]->{message}, qr/kerberos authentication refused/, "error logged");
};

subtest "no channel binding over http" => sub {
    plan tests => 1;
    # Channel binding only applies to TLS, a server requiring it refuses http
    my $response = _request('/strict');
    is($response->code(), 401, "response is 401");
};

$server->stop();

# Same tests over https, with a server checking channel binding like WinRM. The
# test server answers with HTTP/1.0 and closes the connection after the 401
# answer, like WinRM does, so the agent has to get the server certificate with
# a dedicated connection. The certificate is issued to 127.0.0.1 and not
# localhost, so it is not verified, like with no-ssl-check option.
SKIP: {
    skip "https test server not supported on $OSNAME", 5 if $OSNAME =~ /^(MSWin32|darwin)$/;

    # Channel binding the server expects, computed from its own certificate
    my $crt = 'resources/ssl/crt/good.pem';
    open my $fh, '<', $crt or die "can't read $crt: $ERRNO";
    my $pem = do { local $INPUT_RECORD_SEPARATOR; <$fh> };
    close $fh;
    my ($base64) = $pem =~ /-----BEGIN CERTIFICATE-----(.*)-----END CERTIFICATE-----/s;
    my $binding = GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint(decode_base64($base64), "RSA-SHA256");
    my $other   = GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint("other certificate", "RSA-SHA256");

    $server = GLPI::Test::Server->new(
        port    => $port,
        ssl     => 1,
        crt     => $crt,
        key     => 'resources/ssl/key/good.pem',
    );
    $server->set_dispatch({
        '/wsman'    => _negotiate(),
        # WinRM with CbtHardeningLevel set to Strict
        '/strict'   => _negotiate(binding => $binding, strict => 1),
        # WinRM with CbtHardeningLevel set to Relaxed
        '/relaxed'  => _negotiate(binding => $binding),
        # Server certificate seen by the agent is not the one of the server,
        # like when a man-in-the-middle relays the token over its own TLS
        # connection
        '/mitm'     => _negotiate(binding => $other),
    });
    $server->background();

    subtest "https: authenticated by server not checking channel binding" => sub {
        plan tests => 1;
        my $response = _request('/wsman', scheme => 'https', no_ssl_check => 1);
        ok($response->is_success(), "response is success");
    };

    subtest "https: authenticated by server requiring channel binding" => sub {
        plan tests => 2;
        my $response = _request('/strict', scheme => 'https', no_ssl_check => 1);
        ok($response->is_success(), "response is success");
        is($response->content(), "authenticated as ".$realm->client(), "server authenticated agent");
    };

    subtest "https: authenticated by server checking channel binding when provided" => sub {
        plan tests => 1;
        my $response = _request('/relaxed', scheme => 'https', no_ssl_check => 1);
        ok($response->is_success(), "response is success");
    };

    subtest "https: token bound to another server certificate refused" => sub {
        plan tests => 2;
        my $response = _request('/mitm', scheme => 'https', no_ssl_check => 1);
        is($response->code(), 401, "response is 401");
        like($logger->{backends}->[0]->{message}, qr/kerberos authentication refused/, "error logged");
    };

    subtest "https: several requests with the same client" => sub {
        plan tests => 3;
        my $client = _client(no_ssl_check => 1);
        foreach my $index (1..3) {
            my $response = _request('/strict', scheme => 'https', client => $client, body => "<request>$index</request>");
            is($response->content(), "authenticated as ".$realm->client().": <request>$index</request>", "request $index authenticated with channel binding");
        }
    };

    $server->stop();
}

$realm->stop();
