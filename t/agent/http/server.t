#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Config;
use English qw(-no_match_vars);
use LWP::UserAgent;
use Socket;
use Test::More;
use Test::Exception;
use Test::MockModule;
use UNIVERSAL::require;
use Time::HiRes qw(usleep);
use Net::IP;

use GLPI::Test::Agent;
use GLPI::Agent::HTTP::Server;
use GLPI::Agent::Logger;
use GLPI::Test::Utils;

plan skip_all => 'Not working on github action windows image'
    if $OSNAME eq 'MSWin32' && exists($ENV{GITHUB_ACTIONS});

plan tests => 21;

my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ]
);

my $server;

my $module = Test::MockModule->new('GLPI::Agent::HTTP::Server');

lives_ok {
    $server = GLPI::Agent::HTTP::Server->new(
        agent     => GLPI::Test::Agent->new(),
        ip        => '127.0.0.1',
        logger    => $logger,
        htmldir   => 'share/html'
    );
} 'instanciation with default values: ok';
$server->init();

ok (
    !defined($server->{trust}),
    'No trusted address'
);

ok (
    !$server->_isTrusted('127.0.0.1'),
    'server not trusting 127.0.0.1 address'
);

if (my $pid = fork()) {
    my $timeout = time + 10;
    while (!$server->handleRequests() && time < $timeout) { usleep 100000; };
    waitpid($pid, 0);
    ok($CHILD_ERROR >> 8, 'server listening on default port');
} else {
    my $client = LWP::UserAgent->new(timeout => 2);
    exit $client->get('http://127.0.0.1:62354')->is_success();
}

lives_ok {
    $server = GLPI::Agent::HTTP::Server->new(
        agent     => GLPI::Test::Agent->new(),
        ip        => '127.0.0.1',
        logger    => $logger,
        htmldir   => 'share/html',
        trust     => [ '127.0.0.1', '192.168.0.0/24' ]
    );
} 'instanciation with a list of trusted address: ok';

ok (
    defined($server->{trust}->{'127.0.0.1'}),
    '127.0.0.1 as trusted address'
);

ok (
    defined($server->{trust}->{'127.0.0.1'}),
    '192.168.0.0/24 as trusted range'
);

ok (
    $server->_isTrusted('127.0.0.1'),
    'server trusting 127.0.0.1 address'
);

ok (
    $server->_isTrusted('192.168.0.1'),
    'server trusting 192.168.0.1 address'
);

lives_ok {
    $server = GLPI::Agent::HTTP::Server->new(
        agent     => GLPI::Test::Agent->new(),
        ip        => '127.0.0.1',
        logger    => $logger,
        htmldir   => 'share/html',
        trust     => [ '127.0.0.1', 'localhost', 'th1sIsNowh3re' ]
    );
} 'instanciation with a list of trusted address: ok';

ok (
    defined($server->{trust}->{'127.0.0.1'}),
    '127.0.0.1 as trusted address'
);

ok (
    defined($server->{trust}->{'localhost'}),
    'localhost as trusted address'
);

ok (
    !defined($server->{trust}->{'th1sIsNowh3re'}),
    'th1sIsNowh3re as not trusted address'
);

ok (
    $server->_isTrusted('127.0.0.1'),
    'server trusting localhost address'
);

ok (
    !$server->_isTrusted('1.2.3.4'),
    'do not trust unknown host 1.2.3.4'
);

$module->mock('compile', sub {
    my ($string, $logger) = @_;
    if ($string eq 'th1sIsNowh3re') {
        # Emulate 'th1sIsNowh3re' resolves to 1.2.3.4
        return $module->original('compile')->("1.2.3.4", $logger);
    } else {
        return $module->original('compile')->($string, $logger);
    }
});

# Expire trusted cache so trust will be computed again on next _isTrusted call
$server->{trusted_cache_expiration} = 0;

ok (
    $server->_isTrusted('1.2.3.4'),
    'trust host "th1sIsNowh3re" now as 1.2.3.4 ip'
);

# Trusted cache must have been updated
ok (
    $server->{trusted_cache_expiration} > time,
    'trust expiration is in the future'
);

# find an available port
my $port = GLPI::Agent::Tools::first { test_port($_) } 8080 .. 8180;

lives_ok {
    $server = GLPI::Agent::HTTP::Server->new(
        agent     => GLPI::Test::Agent->new(),
        ip        => '127.0.0.1',
        logger    => $logger,
        port      => $port,
        htmldir   => 'share/html',
    );
} 'instanciation with specific port: ok';
$server->init();

ok (
    !defined($server->{trust}),
    'No trusted address'
);

if (my $pid = fork()) {
    my $timeout = time + 10;
    while (!$server->handleRequests() && time < $timeout) { usleep 100000; };
    waitpid($pid, 0);
    ok($CHILD_ERROR >> 8, 'server listening on specific port');
} else {
    my $client = LWP::UserAgent->new(timeout => 2);
    exit $client->get("http://127.0.0.1:$port")->is_success();
}

if (my $pid = fork()) {
    my $timeout = time + 10;
    while (!$server->handleRequests() && time < $timeout) { usleep 100000; };
    waitpid($pid, 0);
    ok(
        $CHILD_ERROR >> 8,
        'server still listening on specific port after ALARM signal in child');
} else {
    alarm 3;
    my $client = LWP::UserAgent->new(timeout => 2);
    exit $client->get("http://127.0.0.1:$port")->is_success();
}
