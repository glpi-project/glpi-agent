#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::More;

use GLPI::Agent::XML::Response;
use GLPI::Agent::SNMP::Live;

plan tests => 12;

my $snmp;
throws_ok {
    $snmp = GLPI::Agent::SNMP::Live->new();
} qr/^no hostname parameter/,
'instanciation: no hostname parameter';

throws_ok {
    $snmp = GLPI::Agent::SNMP::Live->new(
        hostname => 'localhost',
        version  => 'foo'
    );
} qr/^invalid SNMP version/,
'instanciation: invalid version parameter';

throws_ok {
    $snmp = GLPI::Agent::SNMP::Live->new(
        hostname => 'localhost',
        version  => 5
    );
} qr/^invalid SNMP version/,
'instanciation: invalid version parameter';

throws_ok {
    $snmp = GLPI::Agent::SNMP::Live->new(
        hostname => 'localhost',
        version => 1
    );
} qr/[Cc]ommunity (is )?not defined/,
'instanciation: undefined community';

throws_ok {
    $snmp = GLPI::Agent::SNMP::Live->new(
        version   => 1,
        community => 'public',
        hostname  => 'none'
    );
} qr/^Unable to resolve the UDP\/IPv4 address "none"/,
'instanciation: unresolvable host';

throws_ok {
    $snmp = GLPI::Agent::SNMP::Live->new(
        version   => 1,
        community => 'public',
        hostname  => '1.1.1.1'
    );
} qr/no response from host 1.1.1.1/,
'instanciation: unresponding host';

SKIP: {
skip 'live SNMP test disabled', 6 unless $ENV{TEST_LIVE_SNMP};

lives_ok {
    $snmp = GLPI::Agent::SNMP::Live->new(
        version   => '1',
        community => 'public',
        hostname  => 'localhost'
    );
} 'SNMPv1: instanciation';

is(
    $snmp->get('1.3.6.1.2.1.1.9.1.3.3'),
    'The SNMP Management Architecture MIB.',
    'SNMPv1: simple value query'
);

cmp_deeply(
    $snmp->walk('1.3.6.1.2.1.1.9.1.3'),
    {
        1  => 'The MIB for Message Processing and Dispatching.',
        2  => 'The management information definitions for the SNMP User-based Security Model.',
        3  => 'The SNMP Management Architecture MIB.',
        4  => 'The MIB module for SNMPv2 entities',
        5  => 'The MIB module for managing TCP implementations',
        6  => 'The MIB module for managing IP and ICMP implementations',
        7  => 'The MIB module for managing UDP implementations',
        8  => 'View-based Access Control Model for SNMP.',
        9  => 'The MIB modules for managing SNMP Notification, plus filtering.',
        10 => 'The MIB module for logging SNMP Notifications.'
    },
    'SNMPv1: multiple value query'
);

lives_ok {
    $snmp = GLPI::Agent::SNMP::Live->new(
        version   => '2c',
        community => 'public',
        hostname  => 'localhost'
    );
} 'SNMPv2c: instanciation';

is(
    $snmp->get('1.3.6.1.2.1.1.9.1.3.3'),
    'The SNMP Management Architecture MIB.',
    'SNMPv2c: simple value query'
);

cmp_deeply(
    $snmp->walk('1.3.6.1.2.1.1.9.1.3'),
    {
        1  => 'The MIB for Message Processing and Dispatching.',
        2  => 'The management information definitions for the SNMP User-based Security Model.',
        3  => 'The SNMP Management Architecture MIB.',
        4  => 'The MIB module for SNMPv2 entities',
        5  => 'The MIB module for managing TCP implementations',
        6  => 'The MIB module for managing IP and ICMP implementations',
        7  => 'The MIB module for managing UDP implementations',
        8  => 'View-based Access Control Model for SNMP.',
        9  => 'The MIB modules for managing SNMP Notification, plus filtering.',
        10 => 'The MIB module for logging SNMP Notifications.'
    },
    'SNMPv2c: multiple value query'
);
}
