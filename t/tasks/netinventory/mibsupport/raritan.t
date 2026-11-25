#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep qw(cmp_deeply);
use Test::NoWarnings;

use GLPI::Agent::SNMP::Mock;
use GLPI::Agent::SNMP::Device;
use GLPI::Agent::SNMP::MibSupport::Raritan;

plan tests => 3;

my $snmp = GLPI::Agent::SNMP::Mock->new(
    hash => {
        '.1.3.6.1.4.1.13742.6.3.2.1.1.6.1'      => [ 'STRING', '16A' ],
        '.1.3.6.1.4.1.13742.6.3.5.3.1.2.1.1'    => [ 'STRING', '1' ],
        '.1.3.6.1.4.1.13742.6.3.5.3.1.2.1.2'    => [ 'STRING', '2' ],
        '.1.3.6.1.4.1.13742.6.3.5.3.1.2.1.10'   => [ 'STRING', '10' ],
        '.1.3.6.1.4.1.13742.6.3.5.3.1.3.1.1'    => [ 'STRING', 'Web server 01' ],
        '.1.3.6.1.4.1.13742.6.3.5.3.1.3.1.2'    => [ 'STRING', '' ],
        '.1.3.6.1.4.1.13742.6.3.5.3.1.29.1.1'   => [ 'STRING', 'IEC 60320 C13' ],
        '.1.3.6.1.4.1.13742.6.3.5.3.1.29.1.2'   => [ 'STRING', 'IEC 60320 C19' ],
        '.1.3.6.1.4.1.13742.6.3.5.3.1.29.1.10'  => [ 'STRING', 'IEC 60320 C13' ],
    }
);

my $device = GLPI::Agent::SNMP::Device->new(
    snmp => $snmp,
    glpi => "12"
);

# Load MibSupport and set type based on glpi 12 support before running MibSupport
$device->loadMibSupport('.1.3.6.1.4.1.13742.6', {});
$device->setType();
$device->runMibSupport();

ok($device->{TYPE} eq "PDU", "check pdu type");

cmp_deeply(
    $device->{PDU},
    {
        TYPE    => '16A',
        PLUGS   => [
            {
                NAME        => '1',
                CUSTOM_NAME => 'Web server 01',
                NUMBER      => '1',
                TYPE        => 'IEC 60320 C13',
            },
            {
                NAME        => '2',
                NUMBER      => '2',
                TYPE        => 'IEC 60320 C19',
            },
            {
                NAME        => '10',
                NUMBER      => '10',
                TYPE        => 'IEC 60320 C13',
            },
        ],
    },
    'Raritan PDU plugs use outlet label as NAME and outlet name as CUSTOM_NAME'
);
