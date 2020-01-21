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
use UNIVERSAL::require;
use Time::HiRes qw(usleep);

use FusionInventory::Test::Agent;
use FusionInventory::Agent::HTTP::Server;
use FusionInventory::Agent::Logger;
use FusionInventory::Test::Utils;

plan skip_all => 'Not working on github action windows image'
    if $OSNAME eq 'MSWin32' && exists($ENV{GITHUB_ACTIONS});

plan tests => 12;

my $logger = FusionInventory::Agent::Logger->new(
    logger => [ 'Test' ]
);

my $server;

lives_ok {
    $server = FusionInventory::Agent::HTTP::Server->new(
        agent     => FusionInventory::Test::Agent->new(),
        logger    => $logger,
        htmldir   => 'share/html'
    );
} 'instanciation with default values: ok';
$server->init();

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
    $server = FusionInventory::Agent::HTTP::Server->new(
        agent     => FusionInventory::Test::Agent->new(),
        logger    => $logger,
        htmldir   => 'share/html',
        trust     => [ '127.0.0.1', '192.168.0.0/24' ]
    );
} 'instanciation with a list of trusted address: ok';

ok (
    $server->_isTrusted('127.0.0.1'),
    'server trusting 127.0.0.1 address'
);

ok (
    $server->_isTrusted('192.168.0.1'),
    'server trusting 192.168.0.1 address'
);

lives_ok {
    $server = FusionInventory::Agent::HTTP::Server->new(
        agent     => FusionInventory::Test::Agent->new(),
        logger    => $logger,
        htmldir   => 'share/html',
        trust     => [ '127.0.0.1', 'localhost', 'th1sIsNowh3re' ]
    );
} 'instanciation with a list of trusted address: ok';

ok (
    $server->_isTrusted('127.0.0.1'),
    'server trusting localhost address'
);

ok (
    !$server->_isTrusted('1.2.3.4'),
    'do not trust unknown host 1.2.3.4'
);

# find an available port
my $port = FusionInventory::Agent::Tools::first { test_port($_) } 8080 .. 8180;

lives_ok {
    $server = FusionInventory::Agent::HTTP::Server->new(
        agent     => FusionInventory::Test::Agent->new(),
        logger    => $logger,
        port      => $port,
        htmldir   => 'share/html',
    );
} 'instanciation with specific port: ok';
$server->init();

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
