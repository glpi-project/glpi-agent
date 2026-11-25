#!/usr/bin/perl

# Test channel binding helpers used by kerberos authentication over https
#
# The end-to-end test with a real KDC and a server checking channel binding
# is done in t/agent/http/client/kerberos.t. This test covers what doesn't
# need GSSAPI nor a KDC: the RFC 5929 tls-server-end-point computation and how
# the server certificate is retrieved, from the kept-alive connection or from
# a dedicated one.

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use MIME::Base64;
use Digest::SHA qw(sha256 sha384 sha512);
use File::Temp;
use UNIVERSAL::require;
use URI;
use Test::More;

use GLPI::Agent::Logger;
use GLPI::Agent::HTTP::Client;
use GLPI::Agent::HTTP::Kerberos;
use GLPI::Test::Utils;

unsetProxyEnvVar();

plan tests => 3;

my $logger = GLPI::Agent::Logger->new(
    logger  => [ 'Test' ],
    debug   => 2,
);

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
    plan tests => scalar(keys(%cases)) + 6;
    is(
        unpack("H*", substr(GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint($der, "ecdsa-with-SHA384"), 21)),
        $der_sha384,
        "hash matches certificate SHA-384 fingerprint"
    );
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

## no critic (ProhibitMultiplePackages)
package FakeSSLSocket;

# Cached socket emulation, only providing the server certificate
sub peer_certificate { $_[0]->{cert} }

sub close {}
