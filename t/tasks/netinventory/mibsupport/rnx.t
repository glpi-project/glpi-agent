#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep qw(cmp_deeply);
use Test::NoWarnings;

use GLPI::Agent::SNMP::Mock;
use GLPI::Agent::SNMP::Device;
use GLPI::Agent::SNMP::MibSupport::RNX;

plan tests => 3;

my $snmp = GLPI::Agent::SNMP::Mock->new(
    hash => {
        '.1.3.6.1.4.1.55108.2.1.2.1.6.1'  => [ 'STRING', 'RN3214' ],
        '.1.3.6.1.4.1.55108.2.9.2.1.2.1'  => [ 'STRING', 'A1' ],
        '.1.3.6.1.4.1.55108.2.9.2.1.2.2'  => [ 'STRING', 'A2' ],
        '.1.3.6.1.4.1.55108.2.9.2.1.2.10' => [ 'STRING', 'B10' ],
        '.1.3.6.1.4.1.55108.2.9.2.1.3.1'  => [ 'STRING', 'Web server 01' ],
        '.1.3.6.1.4.1.55108.2.9.2.1.3.2'  => [ 'STRING', '' ],
        '.1.3.6.1.4.1.55108.2.9.2.1.8.1'  => [ 'INTEGER', 10000 ],
        '.1.3.6.1.4.1.55108.2.9.2.1.8.2'  => [ 'INTEGER', 16000 ],
        '.1.3.6.1.4.1.55108.2.9.2.1.8.10' => [ 'INTEGER', 32000 ],
    }
);

my $device = GLPI::Agent::SNMP::Device->new(
    snmp => $snmp,
    glpi => "12"
);

# Load MibSupport and set type based on glpi 12 support before running MibSupport
$device->loadMibSupport('.1.3.6.1.4.1.55108.1.0', {});
$device->setType();
$device->runMibSupport();

ok($device->{TYPE} eq "PDU", "check pdu type");

cmp_deeply(
    $device->{PDU},
    {
        TYPE    => 'RN3214',
        PLUGS   => [
            {
                NAME        => 'A1',
                CUSTOM_NAME => 'Web server 01',
                NUMBER      => 1,
                TYPE        => 'C13',
            },
            {
                NAME        => 'A2',
                CUSTOM_NAME => '',
                NUMBER      => 2,
                TYPE        => 'C19',
            },
            {
                NAME        => 'B10',
                CUSTOM_NAME => '',
                NUMBER      => 10,
                TYPE        => 'unknown',
            },
        ],
    },
    'RNX PDU plugs use system name as NAME and user defined name as CUSTOM_NAME'
);
