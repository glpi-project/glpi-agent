#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::Deep qw(cmp_deeply);
use Test::Exception;
use Test::More;

use GLPI::Agent::Tools;
use GLPI::Agent::XML::Response;

my %tests = (
    message1 => {
        OPTION => [
            {
                NAME => 'REGISTRY',
                PARAM => [
                    {
                        NAME    => 'blablabla',
                        content => '*',
                        REGTREE => '0',
                        REGKEY  => 'SOFTWARE/Mozilla'
                    }
                 ]
            },
            {
                NAME => 'DOWNLOAD',
                PARAM => [
                    {
                         FRAG_LATENCY   => '10',
                         TIMEOUT        => '30',
                         PERIOD_LATENCY => '1',
                         ON             => '1',
                         TYPE           => 'CONF',
                         PERIOD_LENGTH  => '10',
                         CYCLE_LATENCY  => '6'
                    }
                ]
            }
        ],
        RESPONSE => 'SEND',
        PROLOG_FREQ => '1'
    },
    message2 => {
        OPTION => [
            {
                AUTHENTICATION => [
                    {
                        ID             => '1',
                        AUTHPROTOCOL   => '',
                        PRIVPROTOCOL   => '',
                        USERNAME       => '',
                        AUTHPASSPHRASE => '',
                        VERSION        => '1',
                        COMMUNITY      => 'public',
                        PRIVPASSPHRASE => ''
                    },
                ],
                NAME => 'SNMPQUERY',
                DEVICE => [
                    {
                        ID           => '72',
                        IP           => '192.168.0.151',
                        TYPE         => 'PRINTER',
                        AUTHSNMP_ID  => '1'
                    }
                ],
                PARAM => [
                    {
                        PID           => '1280265498/024',
                        THREADS_QUERY => '4',
                        CORE_QUERY    => '1'
                    }
                ]
            }
        ],
        PROCESSNUMBER => '1280265498/024'
    },
    message3 => {
        OPTION => [
            {
                AUTHENTICATION => [
                    {
                        ID             => '1',
                        AUTHPROTOCOL   => '',
                        PRIVPROTOCOL   => '',
                        USERNAME       => '',
                        AUTHPASSPHRASE => '',
                        VERSION        => '1',
                        COMMUNITY      => 'public',
                        PRIVPASSPHRASE => ''
                    },
                    {
                        ID             => '2',
                        AUTHPROTOCOL   => '',
                        PRIVPROTOCOL   => '',
                        USERNAME       => '',
                        AUTHPASSPHRASE => '',
                        VERSION        => '2c',
                        COMMUNITY      => 'public',
                        PRIVPASSPHRASE => ''
                    }
                ],
                RANGEIP => [
                    {
                        ID      => '1',
                        ENTITY  => '15',
                        IPSTART => '192.168.0.1',
                        IPEND   => '192.168.0.254'
                    },
                ],
                NAME => 'NETDISCOVERY',
                PARAM => [
                    {
                    CORE_DISCOVERY    => '1',
                    PID               => '1280265592/024',
                    THREADS_DISCOVERY => '10'
                    }
                ]
            }
        ],
        PROCESSNUMBER => '1280265592/024'
    },
    message4 => {
        OPTION => [
            {
                comment => 'This is a wrong query as DEVICE is empty',
                AUTHENTICATION => [
                    {
                        ID             => '1',
                        AUTHPROTOCOL   => '',
                        PRIVPROTOCOL   => '',
                        USERNAME       => '',
                        AUTHPASSPHRASE => '',
                        VERSION        => '1',
                        COMMUNITY      => 'public',
                        PRIVPASSPHRASE => ''
                    },
                ],
                NAME => 'SNMPQUERY',
                DEVICE => [ '' ],
                PARAM => [
                    {
                        PID           => '1',
                        THREADS_QUERY => '1',
                        CORE_QUERY    => '1'
                    }
                ]
            }
        ],
        PROCESSNUMBER => '1'
    }
);

plan tests => 2 * (scalar keys %tests);

foreach my $test (keys %tests) {
    my $file = "resources/xml/response/$test.xml";
    my $string = getAllLines(file => $file);
    my $message = GLPI::Agent::XML::Response->new(
        content => $string
    );

    my $content = $message->getContent();
    cmp_deeply($content, $tests{$test}, $test);

    subtest 'options' => sub {
        my $options = $content->{OPTION};
        plan tests => scalar @$options;
        foreach my $option (@$options) {
            cmp_deeply(
                $message->getOptionsInfoByName($option->{NAME}),
                $option,
                "$test option $option->{NAME}"
            );
        }
    };
}
