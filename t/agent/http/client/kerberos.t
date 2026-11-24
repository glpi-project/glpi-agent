#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use HTTP::Request;
use HTTP::Response;
use MIME::Base64;
use Digest::SHA qw(sha256 sha384 sha512);
use URI;
use File::Temp;
use UNIVERSAL::require;
use Test::More;
use Test::MockModule;

use GLPI::Agent::Logger;
use GLPI::Agent::HTTP::Client;
use GLPI::Agent::HTTP::Kerberos;
use GLPI::Test::Utils;

unsetProxyEnvVar();

plan tests => 13;

my $logger = GLPI::Agent::Logger->new(
    logger  => [ 'Test' ],
    debug   => 2,
);

# Mock kerberos token provider as GSSAPI & a KDC are not available while testing
my ($token, $verified, $kerberos_error, @bindings);
my $kerberos = Test::MockModule->new('GLPI::Agent::HTTP::Kerberos');
$kerberos->mock(new => sub {
    my ($class, %params) = @_;
    return bless { _host => $params{host} }, $class;
});
$kerberos->mock(token => sub { $token });
$kerberos->mock(verify => sub { $verified });
$kerberos->mock(error => sub { $kerberos_error });
$kerberos->mock(channel_binding => sub { push @bindings, $_[1] });

# Mock server certificate retrieval
my @certificate;
my $client_module = Test::MockModule->new('GLPI::Agent::HTTP::Client');
$client_module->mock(_getServerCertificate => sub { @certificate });

# Self-signed ECDSA certificate signed with SHA-384
my $pem = <<'PEM';
-----BEGIN CERTIFICATE-----
MIIBkDCCATegAwIBAgIUajwjLstMwFkFSg3alfk9sZVhj/YwCgYIKoZIzj0EAwMw
HTEbMBkGA1UEAwwSd2luaG9zdC5kb21haW4udGxkMCAXDTI2MTEyMzE1MTc0OVoY
DzIxMjYxMDMwMTUxNzQ5WjAdMRswGQYDVQQDDBJ3aW5ob3N0LmRvbWFpbi50bGQw
WTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATeu5Swao1qIBQ7AedYx4hgdA4oyXWV
6h/Fho3YJNhDsXz8g+/Nh9KD5VeF4V5dF45ILyD8oPULegjZh/rlbDb+o1MwUTAd
BgNVHQ4EFgQUqMU3bN74AjclTfyApA2ES/TKyNswHwYDVR0jBBgwFoAUqMU3bN74
AjclTfyApA2ES/TKyNswDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAwNHADBE
AiAfBWyo8f1dWpzqj7yUwP1Jf6O7g53wmdBy5eJdyvlg+QIgWABt019smX08yI4A
plq92L4dnBSqY0GopDmc7B/NvDM=
-----END CERTIFICATE-----
PEM
# Test only private key of the certificate
my $key = <<'PEM';
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgoEZVBw6toYeS732k
fc5rr7fexRNiUUVn1slVuMph8mqhRANCAATeu5Swao1qIBQ7AedYx4hgdA4oyXWV
6h/Fho3YJNhDsXz8g+/Nh9KD5VeF4V5dF45ILyD8oPULegjZh/rlbDb+
-----END PRIVATE KEY-----
PEM
my $der = decode_base64(join('', grep { !/^-----/ } split(/\n/, $pem)));
my $der_sha384 = "c4ef760421ad16d8e62588d212d88866c212fd8146a6690bf815f14845f093522d929de07e8092d07f2312c7f5f40a6c";

# Mock LWP::UserAgent to return prepared responses and keep sent requests
my (@responses, @requests);
my $ua = Test::MockModule->new('LWP::UserAgent');
$ua->mock(request => sub {
    my ($self, $request) = @_;
    push @requests, $request->clone();
    return shift(@responses);
});

sub _response {
    my ($code, %headers) = @_;
    my $response = HTTP::Response->new($code);
    foreach my $header (keys(%headers)) {
        my $values = ref($headers{$header}) ? $headers{$header} : [ $headers{$header} ];
        $response->push_header($header => $_) foreach @{$values};
    }
    return $response;
}

sub _run {
    my (%params) = @_;

    @requests = ();
    @bindings = ();
    @responses = @{$params{responses}};
    @certificate = @{$params{certificate} // []};
    $token = $params{token};
    $verified = $params{verified} // 1;
    $kerberos_error = $params{error} // '';

    my $client = GLPI::Agent::HTTP::Client->new(
        logger      => $logger,
        kerberos    => $params{kerberos} // 1,
        user        => $params{user},
        password    => $params{password},
        no_ssl_check=> 1,
    );

    my $request = HTTP::Request->new(POST => $params{url} // "http://winhost.domain.tld:5985/wsman/");
    return $client->request($request);
}

subtest "kerberos authentication success" => sub {
    plan tests => 6;
    my $response = _run(
        token       => "dG9rZW4=",
        responses   => [
            _response(401, 'WWW-Authenticate' => [ 'Negotiate', 'Basic realm="WSMAN"' ]),
            _response(200, 'WWW-Authenticate' => 'Negotiate bXV0dWFs'),
        ],
    );
    ok($response->is_success(), "response is success");
    is(scalar(@requests), 2, "request replayed once");
    ok(!defined($requests[0]->header('Authorization')), "no authorization on first request");
    is($requests[1]->header('Authorization'), "Negotiate dG9rZW4=", "negotiate token submitted");
    unlike($requests[1]->header('Authorization'), qr/^Basic/, "basic not used");
    like($logger->{backends}->[0]->{message} // '', qr/kerberos mutual authentication verified/, "mutual authentication verified");
};

subtest "kerberos authentication success without mutual token" => sub {
    plan tests => 2;
    my $response = _run(
        token       => "dG9rZW4=",
        responses   => [
            _response(401, 'WWW-Authenticate' => 'Negotiate'),
            _response(200),
        ],
    );
    ok($response->is_success(), "response is success");
    is(scalar(@requests), 2, "request replayed once");
};

subtest "kerberos preferred to basic even with credentials" => sub {
    plan tests => 2;
    my $response = _run(
        token       => "dG9rZW4=",
        user        => "user",
        password    => "pass",
        responses   => [
            _response(401, 'WWW-Authenticate' => 'Basic realm="WSMAN", Negotiate'),
            _response(200),
        ],
    );
    ok($response->is_success(), "response is success");
    is($requests[1]->header('Authorization'), "Negotiate dG9rZW4=", "negotiate token submitted");
};

subtest "negotiate not offered by server" => sub {
    plan tests => 3;
    my $response = _run(
        token       => "dG9rZW4=",
        responses   => [
            _response(401, 'WWW-Authenticate' => 'Basic realm="WSMAN"'),
        ],
    );
    is($response->code(), 401, "response is 401");
    is(scalar(@requests), 1, "request not replayed");
    like($logger->{backends}->[0]->{message}, qr/kerberos authentication not offered by server/, "error logged");
};

subtest "kerberos token failure" => sub {
    plan tests => 3;
    my $response = _run(
        error       => "failed to get kerberos token for HTTP/winhost.domain.tld: No credentials cache found",
        responses   => [
            _response(401, 'WWW-Authenticate' => 'Negotiate'),
        ],
    );
    is($response->code(), 401, "response is 401");
    is(scalar(@requests), 1, "request not replayed");
    like($logger->{backends}->[0]->{message}, qr/No credentials cache found/, "error logged");
};

subtest "kerberos authentication refused" => sub {
    plan tests => 3;
    my $response = _run(
        token       => "dG9rZW4=",
        responses   => [
            _response(401, 'WWW-Authenticate' => 'Negotiate'),
            _response(401, 'WWW-Authenticate' => 'Negotiate'),
        ],
    );
    is($response->code(), 401, "response is 401");
    is(scalar(@requests), 2, "request replayed once");
    like($logger->{backends}->[0]->{message}, qr/kerberos authentication refused/, "error logged");
};

subtest "kerberos mutual authentication failure" => sub {
    plan tests => 2;
    my $response = _run(
        token       => "dG9rZW4=",
        verified    => 0,
        error       => "kerberos mutual authentication failed",
        responses   => [
            _response(401, 'WWW-Authenticate' => 'Negotiate'),
            _response(200, 'WWW-Authenticate' => 'Negotiate YmFk'),
        ],
    );
    is($response->code(), 401, "server answer not trusted");
    like($logger->{backends}->[0]->{message}, qr/kerberos mutual authentication failed/, "error logged");
};

subtest "no channel binding over http" => sub {
    plan tests => 2;
    my $response = _run(
        token       => "dG9rZW4=",
        certificate => [ $der, "ecdsa-with-SHA384" ],
        responses   => [
            _response(401, 'WWW-Authenticate' => 'Negotiate'),
            _response(200),
        ],
    );
    ok($response->is_success(), "response is success");
    is(scalar(@bindings), 0, "channel binding not set");
};

subtest "channel binding over https" => sub {
    plan tests => 4;
    my $response = _run(
        url         => "https://winhost.domain.tld:5986/wsman/",
        token       => "dG9rZW4=",
        certificate => [ $der, "ecdsa-with-SHA384" ],
        responses   => [
            _response(401, 'WWW-Authenticate' => 'Negotiate'),
            _response(200),
        ],
    );
    ok($response->is_success(), "response is success");
    is(scalar(@bindings), 1, "channel binding set once");
    is($bindings[0], "tls-server-end-point:".sha384($der), "tls-server-end-point binding with sha384");
    is(unpack("H*", substr($bindings[0], 21)), $der_sha384, "binding hash matches certificate");
};

subtest "no channel binding over https without server certificate" => sub {
    plan tests => 4;
    my $response = _run(
        url         => "https://winhost.domain.tld:5986/wsman/",
        token       => "dG9rZW4=",
        responses   => [
            _response(401, 'WWW-Authenticate' => 'Negotiate'),
            _response(200),
        ],
    );
    ok($response->is_success(), "response is success");
    is(scalar(@bindings), 1, "channel binding reset once");
    ok(!defined($bindings[0]), "no channel binding data");
    is($requests[1]->header('Authorization'), "Negotiate dG9rZW4=", "negotiate token submitted");
};

subtest "tls-server-end-point computation" => sub {
    my %cases = (
        'RSA-SHA256'                => \&sha256,
        'sha256WithRSAEncryption'   => \&sha256,
        'RSA-SHA1'                  => \&sha256,
        'RSA-MD5'                   => \&sha256,
        'RSASSA-PSS'                => \&sha256,
        'ED25519'                   => \&sha256,
        'RSA-SHA384'                => \&sha384,
        'ecdsa-with-SHA384'         => \&sha384,
        'RSA-SHA512'                => \&sha512,
        'ecdsa-with-SHA512'         => \&sha512,
    );
    plan tests => scalar(keys(%cases)) + 5;
    foreach my $sigalg (sort keys(%cases)) {
        is(
            GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint($der, $sigalg),
            "tls-server-end-point:".$cases{$sigalg}->($der),
            "hash for $sigalg"
        );
    }
    is(
        GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint($der),
        "tls-server-end-point:".sha256($der),
        "sha256 without signature algorithm"
    );
    is(
        GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint($der, "RSA-SHA512/224"),
        "tls-server-end-point:".Digest::SHA->new(512224)->add($der)->digest,
        "hash for RSA-SHA512/224"
    );
    is(
        GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint($der, "RSA-SHA224"),
        "tls-server-end-point:".Digest::SHA->new(224)->add($der)->digest,
        "hash for RSA-SHA224"
    );
    ok(!defined(GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint(undef, "RSA-SHA256")), "no binding without certificate");
    ok(!defined(GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint("", "RSA-SHA256")), "no binding with empty certificate");
};

subtest "server certificate from kept-alive connection" => sub {
    plan skip_all => "Net::SSLeay required" unless Net::SSLeay->require();
    plan tests => 3;

    $client_module->unmock('_getServerCertificate');

    my $bio = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem());
    Net::SSLeay::BIO_write($bio, $pem);
    my $x509 = Net::SSLeay::PEM_read_bio_X509($bio);
    Net::SSLeay::BIO_free($bio);

    my $client = GLPI::Agent::HTTP::Client->new(
        logger      => $logger,
        kerberos    => 1,
        no_ssl_check=> 1,
    );
    my $url = URI->new("https://winhost.domain.tld:5986/wsman/");

    my $socket = bless { cert => $x509 }, 'FakeSSLSocket';
    $client->{ua}->conn_cache->deposit('https', 'other.domain.tld:5986', bless({}, 'FakeSSLSocket'));
    $client->{ua}->conn_cache->deposit('https', 'winhost.domain.tld:5986', $socket);

    my ($cert, $sigalg) = $client->_getServerCertificate($url);
    is($cert, $der, "DER certificate from cached connection");
    like($sigalg // '', qr/SHA384/i, "signature algorithm");
    my @kept = grep { $_ == $socket } $client->{ua}->conn_cache->get_connections('https');
    is(scalar(@kept), 1, "connection kept in cache");

    Net::SSLeay::X509_free($x509);
};

subtest "server certificate from dedicated connection" => sub {
    plan skip_all => "fork based TLS server not supported on Windows" if $OSNAME eq 'MSWin32';
    plan skip_all => "IO::Socket::SSL & Net::SSLeay required"
        unless IO::Socket::SSL->require() && Net::SSLeay->require();
    plan tests => 4;

    my $tmpdir = File::Temp->newdir();
    my $certfile = "$tmpdir/cert.pem";
    my $keyfile  = "$tmpdir/key.pem";
    foreach my $file ([ $certfile, $pem ], [ $keyfile, $key ]) {
        open my $fh, '>', $file->[0] or die "can't write $file->[0]: $ERRNO";
        print $fh $file->[1];
        close $fh;
    }

    my $server = IO::Socket::SSL->new(
        Listen          => 5,
        LocalAddr       => '127.0.0.1',
        LocalPort       => 0,
        SSL_server      => 1,
        SSL_cert_file   => $certfile,
        SSL_key_file    => $keyfile,
    ) or die "can't start TLS server: $IO::Socket::SSL::SSL_ERROR";
    my $port = $server->sockport();

    my $pid = fork();
    die "can't fork: $ERRNO" unless defined($pid);
    unless ($pid) {
        while (1) {
            my $conn = $server->accept() or next;
            $conn->close(SSL_fast_shutdown => 1);
        }
    }
    $server->close(SSL_no_shutdown => 1);

    my $client = GLPI::Agent::HTTP::Client->new(
        logger      => $logger,
        kerberos    => 1,
        no_ssl_check=> 1,
        proxy       => 'none',
    );

    my ($cert, $sigalg) = $client->_getServerCertificate(URI->new("https://127.0.0.1:$port/wsman/"));
    is($cert, $der, "DER certificate from dedicated connection");
    like($sigalg // '', qr/SHA384/i, "signature algorithm");

    kill 'TERM', $pid;
    waitpid($pid, 0);

    my @none = $client->_getServerCertificate(URI->new("https://127.0.0.1:$port/wsman/"));
    is(scalar(@none), 0, "no certificate when server is not reachable");

    $client->{ua}->proxy('https', 'http://127.0.0.1:3128');
    @none = $client->_getServerCertificate(URI->new("https://127.0.0.1:$port/wsman/"));
    is(scalar(@none), 0, "no dedicated connection via a proxy");
};

package FakeSSLSocket;

sub peer_certificate { $_[0]->{cert} }

sub close {}
