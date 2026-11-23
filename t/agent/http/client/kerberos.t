#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use HTTP::Request;
use HTTP::Response;
use Test::More;
use Test::MockModule;

use GLPI::Agent::Logger;
use GLPI::Agent::HTTP::Client;
use GLPI::Agent::HTTP::Kerberos;
use GLPI::Test::Utils;

unsetProxyEnvVar();

plan tests => 7;

my $logger = GLPI::Agent::Logger->new(
    logger  => [ 'Test' ],
    debug   => 2,
);

# Mock kerberos token provider as GSSAPI & a KDC are not available while testing
my ($token, $verified, $kerberos_error);
my $kerberos = Test::MockModule->new('GLPI::Agent::HTTP::Kerberos');
$kerberos->mock(new => sub {
    my ($class, %params) = @_;
    return bless { _host => $params{host} }, $class;
});
$kerberos->mock(token => sub { $token });
$kerberos->mock(verify => sub { $verified });
$kerberos->mock(error => sub { $kerberos_error });

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
    @responses = @{$params{responses}};
    $token = $params{token};
    $verified = $params{verified} // 1;
    $kerberos_error = $params{error} // '';

    my $client = GLPI::Agent::HTTP::Client->new(
        logger      => $logger,
        kerberos    => $params{kerberos} // 1,
        user        => $params{user},
        password    => $params{password},
    );

    my $request = HTTP::Request->new(POST => "http://winhost.domain.tld:5985/wsman/");
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
