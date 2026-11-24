#!/usr/bin/perl

# Test GLPI::Agent::HTTP::Kerberos against a real Kerberos realm
#
# No mock is involved: a throwaway MIT Kerberos KDC is started by
# GLPI::Test::Kerberos, the agent gets its ticket from a credentials cache
# initialized by kinit (or from a client keytab) and tokens are accepted with
# the server side GSSAPI API, like a WinRM service would do. See
# t/lib/GLPI/Test/Kerberos.pm for the realm setup.
#
# This test is skipped if GSSAPI perl module or MIT Kerberos KDC tools are not
# installed. On Debian/Ubuntu: apt install libgssapi-perl krb5-kdc krb5-admin-server krb5-user

use strict;
use warnings;
use lib 't/lib';

use Test::More;

use GLPI::Test::Kerberos;

my $unavailable = GLPI::Test::Kerberos->unavailable();
plan skip_all => "Kerberos test realm: $unavailable" if $unavailable;

my $realm = GLPI::Test::Kerberos->new(
    services => [ 'HTTP/winrm.glpi.test' ],
);

require GLPI::Agent::HTTP::Kerberos;

plan tests => 9;

my $tgt  = 'krbtgt/'.$realm->realm().'@'.$realm->realm();
my $http = 'HTTP/winrm.glpi.test@'.$realm->realm();

subtest "token from credentials cache" => sub {
    plan tests => 10;

    # kinit only put the TGT in the credentials cache
    is_deeply([ $realm->tickets() ], [ $tgt ], "only TGT in credentials cache");

    my $kerberos = GLPI::Agent::HTTP::Kerberos->new(host => 'winrm.glpi.test');
    is($kerberos->error(), '', "no error");
    is($kerberos->service(), 'HTTP/winrm.glpi.test', "service principal");

    my $token = $kerberos->token();
    ok($token, "token computed from ticket found in credentials cache");

    # The library used the TGT to get a service ticket from the KDC and kept
    # it in the credentials cache. The token is built from that ticket.
    is_deeply([ $realm->tickets() ], [ $tgt, $http ], "service ticket added to credentials cache");

    # What the WinRM server does
    my ($client, $mutual) = GLPI::Test::Kerberos::accept_token($token);
    is($client, $realm->client(), "server authenticated agent client principal");
    ok($mutual, "server returned a mutual authentication token");

    ok($kerberos->verify($mutual), "server identity verified");
    is($kerberos->error(), '', "still no error");

    # A new token for the same service doesn't need the KDC anymore
    my ($second) = GLPI::Test::Kerberos::accept_token($kerberos->token());
    is($second, $realm->client(), "second token from cached service ticket accepted");
};

subtest "token from client keytab" => sub {
    plan tests => 5;

    # No ticket in credentials cache but the library can get one by itself
    # from a client keytab (MIT Kerberos 1.11 or later)
    my $ccache = 'FILE:'.$realm->file('keytab.ccache');
    local $ENV{KRB5CCNAME} = $ccache;
    local $ENV{KRB5_CLIENT_KTNAME} = 'FILE:'.$realm->client_keytab();

    ok(! -e $realm->file('keytab.ccache'), "no credentials cache");

    my $kerberos = GLPI::Agent::HTTP::Kerberos->new(host => 'winrm.glpi.test');
    my $token = $kerberos->token();
    ok($token, "token computed from client keytab");

    # The library got a TGT with the keytab and stored it with the service
    # ticket in the credentials cache, so the keytab is only used again when
    # the TGT expires
    is_deeply([ $realm->tickets($ccache) ], [ $tgt, $http ], "credentials cache created by the library");

    my ($client, $mutual) = GLPI::Test::Kerberos::accept_token($token);
    is($client, $realm->client(), "server authenticated agent client principal");
    ok($kerberos->verify($mutual), "server identity verified");
};

subtest "no ticket available" => sub {
    plan tests => 2;

    local $ENV{KRB5CCNAME} = 'FILE:'.$realm->file('missing.ccache');

    my $kerberos = GLPI::Agent::HTTP::Kerberos->new(host => 'winrm.glpi.test');
    ok(!defined($kerberos->token()), "no token");
    like($kerberos->error(), qr{^failed to get kerberos token for HTTP/winrm.glpi.test: .*credentials}i, "error");
};

subtest "unknown service principal" => sub {
    plan tests => 2;

    # Typically what happens when the host is not given by its FQDN
    my $kerberos = GLPI::Agent::HTTP::Kerberos->new(host => 'unknown.glpi.test');
    ok(!defined($kerberos->token()), "no token");
    like($kerberos->error(), qr{^failed to get kerberos token for HTTP/unknown.glpi.test: .*not found in Kerberos database}i, "error");
};

subtest "forged mutual authentication token" => sub {
    plan tests => 3;

    my $kerberos = GLPI::Agent::HTTP::Kerberos->new(host => 'winrm.glpi.test');
    ok($kerberos->token(), "token");
    ok(!$kerberos->verify('Zm9yZ2VkIHRva2Vu'), "forged token refused");
    like($kerberos->error(), qr{^kerberos mutual authentication failed for HTTP/winrm.glpi.test}, "error");
};

subtest "mutual authentication token from another context" => sub {
    plan tests => 2;

    # A valid server answer for another request must not be accepted
    my $first  = GLPI::Agent::HTTP::Kerberos->new(host => 'winrm.glpi.test');
    my $second = GLPI::Agent::HTTP::Kerberos->new(host => 'winrm.glpi.test');
    my (undef, $mutual) = GLPI::Test::Kerberos::accept_token($first->token());
    ok($second->token(), "second token");
    ok(!$second->verify($mutual), "mutual token from first context refused");
};

subtest "verify without token" => sub {
    plan tests => 6;

    my $kerberos = GLPI::Agent::HTTP::Kerberos->new(host => 'winrm.glpi.test');
    ok(!$kerberos->verify('Zm9yZ2VkIHRva2Vu'), "nothing to verify before token()");
    like($kerberos->error(), qr{: no pending authentication$}, "error");

    ok($kerberos->token(), "token");
    ok(!$kerberos->verify(''), "missing mutual token refused");
    like($kerberos->error(), qr{: no token provided by server$}, "error");

    # Each verification failure only concerns its own authentication
    my (undef, $mutual) = GLPI::Test::Kerberos::accept_token($kerberos->token());
    ok($kerberos->verify($mutual), "next authentication verified");
};

subtest "channel binding" => sub {
    plan tests => 11;

    # What the agent and the WinRM server compute from the server certificate
    my $binding = GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint("server certificate", "RSA-SHA256");
    my $other   = GLPI::Agent::HTTP::Kerberos::tlsServerEndPoint("other certificate", "RSA-SHA256");

    my $kerberos = GLPI::Agent::HTTP::Kerberos->new(host => 'winrm.glpi.test');
    $kerberos->channel_binding($binding);

    my ($client, $mutual) = GLPI::Test::Kerberos::accept_token($kerberos->token(), binding => $binding, strict => 1);
    is($client, $realm->client(), "token with expected binding accepted by strict server");
    ok($kerberos->verify($mutual), "server identity verified with channel binding");

    # Server certificate seen by the agent is not the one of the server, like
    # when a man-in-the-middle relays the token over its own TLS connection
    ($client) = GLPI::Test::Kerberos::accept_token($kerberos->token(), binding => $other);
    ok(!defined($client), "token with another binding refused");

    # A server not checking channel binding still accepts the token
    ($client, $mutual) = GLPI::Test::Kerberos::accept_token($kerberos->token());
    is($client, $realm->client(), "token with binding accepted by server not checking it");
    ok($kerberos->verify($mutual), "server identity verified without server channel binding");

    # Reset channel binding
    $kerberos->channel_binding();

    ($client) = GLPI::Test::Kerberos::accept_token($kerberos->token(), binding => $binding, strict => 1);
    ok(!defined($client), "token without binding refused by strict server");

    ($client, $mutual) = GLPI::Test::Kerberos::accept_token($kerberos->token(), binding => $binding);
    is($client, $realm->client(), "token without binding accepted by relaxed server");
    ok($kerberos->verify($mutual), "server identity verified");

    $kerberos->channel_binding('');
    ($client) = GLPI::Test::Kerberos::accept_token($kerberos->token(), binding => $binding, strict => 1);
    ok(!defined($client), "empty binding data means no binding");

    # Channel binding is kept for following tokens
    $kerberos->channel_binding($binding);
    foreach my $index (1..2) {
        ($client) = GLPI::Test::Kerberos::accept_token($kerberos->token(), binding => $binding, strict => 1);
        is($client, $realm->client(), "token $index accepted by strict server");
    }
};

subtest "no host" => sub {
    plan tests => 2;

    my $kerberos = GLPI::Agent::HTTP::Kerberos->new();
    is($kerberos->error(), "no host defined for kerberos authentication", "error");
    ok(!defined($kerberos->token()), "no token");
};

$realm->stop();
