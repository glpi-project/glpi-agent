#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use JSON::PP;
use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::More;

use GLPI::Agent::Logger;
use GLPI::Agent::Version;
use GLPI::Agent::XML::Response;

use GLPI::Agent::Protocol::Contact;

my %answers = (
    # each case: [
    #   boolean telling the message must be supported,
    #   boolean telling the message is valid regarding the protocol,
    #   message
    # ]
    "as expected-1" => {
        must_be_understood  => 1,
        must_be_protocol    => 1,
        message             => qq(
            {
                "status": "ok",
                "tasks": [],
                "expiration": 24
            }
        )
    },
    "as expected-2" => {
        must_be_understood  => 1,
        must_be_protocol    => 1,
        message             => qq(
            {
                "status": "ok",
                "tasks": [],
                "expiration": "24"
            }
        )
    },
    "as expected-3" => {
        must_be_understood  => 1,
        must_be_protocol    => 1,
        message             => qq(
            {
                "status": "ok",
                "tasks": [],
                "expiration": "24h"
            }
        )
    },
    "as expected-4" => {
        must_be_understood  => 1,
        must_be_protocol    => 1,
        message             => qq(
            {
                "status": "ok",
                "tasks": [],
                "expiration": "3600s"
            }
        )
    },
    "as expected-5" => {
        must_be_understood  => 1,
        must_be_protocol    => 1,
        message             => qq(
            {
                "status": "ok",
                "tasks": [],
                "expiration": "240m"
            }
        )
    },
    "unexpected-xml" => {
        must_be_understood  => 0,
        must_be_protocol    => 0,
        message             => qq(
            <REPLY><PROLOG_FREQ>24</PROLOG_FREQ></REPLY>
        )
    },
    "unexpected empty" => {
        must_be_understood  => 0,
        must_be_protocol    => 0,
        message             => qq()
    },
    "wrong empty" => {
        must_be_understood  => 1,
        must_be_protocol    => 0,
        message             => qq({})
    },
    "invalid json (missing comma)" => {
        must_be_understood  => 0,
        must_be_protocol    => 0,
        message             => qq(
            {
                "status": "ok"
                "tasks": [],
                "expiration": 24
            }
        )
    },
    "invalid json (unexpected comma)" => {
        must_be_understood  => 0,
        must_be_protocol    => 0,
        message             => qq(
            {
                "status": "ok",
                "tasks": [],
                "expiration": 24,
            }
        )
    },
    "missing status" => {
        must_be_understood  => 1,
        must_be_protocol    => 0,
        message             => qq(
            {
                "tasks": [],
                "expiration": 24
            }
        )
    },
    "empty status" => {
        must_be_understood  => 1,
        must_be_protocol    => 0,
        message             => qq(
            {
                "status": "",
                "tasks": [],
                "expiration": 24
            }
        )
    },
    "empty status" => {
        must_be_understood  => 1,
        must_be_protocol    => 0,
        message             => qq(
            {
                "status": "",
                "tasks": [],
                "expiration": 24
            }
        )
    },
);

plan tests => 7 + 3 * (keys %answers);

my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ]
);

# Simple CONTACT request
my $contact;
my $deviceid = "device-id-123456789";
my $tag = "my-beautiful-tag";
my $installed_tasks = [ "Task1", "Task2", "TaskX" ];
my $enabled_tasks   = [ "Task1", "Task2" ];

lives_ok {
    $contact = GLPI::Agent::Protocol::Contact->new(
        logger      => $logger,
        deviceid    => $deviceid,
        tag         => $tag,
        "installed-tasks"   => $installed_tasks,
        "enabled-tasks"     => $enabled_tasks,
    );
} "CONTACT request";

isa_ok($contact, "GLPI::Agent::Protocol::Contact");

is($contact->get("tag"), $tag, "Contact request: get tag");
is($contact->get("deviceid"), $deviceid, "Contact request: get deviceid");

my $content;
lives_ok {
    $content = $contact->getContent();
} "Contact request: get content access";

my $decoded_content;
lives_ok {
    $decoded_content = JSON::PP::decode_json($content);
} "Contact request: content must be a JSON";

my $expected_content = {
    name                => $GLPI::Agent::Version::PROVIDER . "-Agent",
    version             => $GLPI::Agent::Version::VERSION,
    deviceid            => $deviceid,
    tag                 => $tag,
    action              => "contact",
    "installed-tasks"   => $installed_tasks,
    "enabled-tasks"     => $enabled_tasks,
};

cmp_deeply($decoded_content, $expected_content, "Contact request: content check");

# CONTACT answers are used in:
# 1. GLPI::Agent                     when contacting a GLPI server
# 2. GLPI::Agent::HTTP::Client::OCS  when interpreting a GLPI server answer

my $answer;
foreach my $case (keys(%answers)) {
    my $message = $answers{$case}->{message};
    my $lives   = $answers{$case}->{must_be_understood};
    my $valid   = $answers{$case}->{must_be_protocol};
    # Message must fail being a XML response
    if ($case !~ /^unexpected-xml/) {
        dies_ok {
            $answer = GLPI::Agent::XML::Response->new(
                content => $message,
            );
        } "CONTACT answer not an XML: $case";
    } else {
        lives_ok {
            $answer = GLPI::Agent::XML::Response->new(
                content => $message,
            );
        } "CONTACT answer is an XML: $case";
    }
    if ($lives) {
        lives_ok {
            $answer = GLPI::Agent::Protocol::Contact->new(
                logger  => $logger,
                message => $message,
            );
        } "CONTACT answer creation: $case ?";
        ok($answer->is_valid_message == $valid, "Contact answer $case");
    } else {
        dies_ok {
            $answer = GLPI::Agent::Protocol::Contact->new(
                logger  => $logger,
                message => $message,
            );
        } "CONTACT answer creation: $case ?";
        pass("$case: nothing to check validity on");
    }
}
