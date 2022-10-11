#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::More;

use GLPI::Agent::Logger;

use GLPI::Agent::Protocol::Message;

plan tests => 32;

my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ]
);

my $message;

# Simple message
lives_ok {
    $message = GLPI::Agent::Protocol::Message->new(
        logger  => $logger,
        message => qq({}),
    );
} "Simple empty message";
isa_ok($message, "GLPI::Agent::Protocol::Message");

my $set;
lives_ok {
    $set = $message->set();
} "Empty message set";
is($set, undef, "Empty message set result");

lives_ok {
    $set = $message->set("{}");
} "Empty json set";
cmp_deeply($set, {}, "Empty json set result");

lives_ok {
    $set = $message->set(qq({"test":"passed"}));
} "Test json set";
cmp_deeply($set, { test => "passed" }, "Test json set result");
is($message->get("test"), "passed", "Test json get result");

my $content;
lives_ok {
    $content = $message->getContent();
} "Test message getContent";
is($content, qq({
   "test": "passed"
}
), "Message content check");               # 11

# Message as hash
lives_ok {
    $message = GLPI::Agent::Protocol::Message->new(
        logger  => $logger,
        message => {},
    );
} "Simple message as hash";
isa_ok($message, "GLPI::Agent::Protocol::Message");

# Expiration in message
is($message->expiration, 0, "No expiration");
lives_ok {
    $message = GLPI::Agent::Protocol::Message->new(
        logger  => $logger,
        message => {
            expiration  => 24,
        },
    );
} "Expiration 24";
isa_ok($message, "GLPI::Agent::Protocol::Message");
is($message->expiration, 86400, "Expiration 24 in seconds");
$message->set('{"expiration": "3600s"}');
is($message->expiration, 3600, "Expiration 3600 seconds");
$message->set('{"expiration": "120m"}');
is($message->expiration, 7200, "Expiration 7200 seconds");
$message->set('{"expiration": "48h"}');
is($message->expiration, 172800, "Expiration 172800 seconds");
$message->set('{"expiration": "4d"}');
is($message->expiration, 345600, "Expiration 345600 seconds");
$message->set('{"expiration": 36}');
is($message->expiration, 129600, "Expiration 129600 seconds");              # 22

is($message->status, "", "No status");
is($message->action, "inventory", "No action");

lives_ok {
    $message = GLPI::Agent::Protocol::Message->new(
        logger  => $logger,
        message => qq({
            "expiration": 24,
            "action": "test",
            "status": "ok"
        }),
    );
} "Complex message";
is($message->status, "ok", "Ok status");
is($message->action, "test", "Test action");

lives_ok {
    $message = GLPI::Agent::Protocol::Message->new(
        logger              => $logger,
        supported_params    => [ "action", "expiration" ],
        action              => "test",
        expiration          => "2h",
    );
} "Complex message with params";
is($message->status, "", "No status");
is($message->action, "test", "Test action (2)");
is($message->expiration, 7200, "Expiration 7200 seconds");
is(keys(%{$message->get}), 2, "2 params sets");                             # 32
