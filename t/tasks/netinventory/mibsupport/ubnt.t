#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep qw(cmp_deeply superhashof);
use Test::NoWarnings;

use GLPI::Agent::SNMP::Mock;
use GLPI::Agent::SNMP::Device;
use GLPI::Agent::SNMP::Hardware;
use GLPI::Agent::SNMP::MibSupport::Ubnt;

# Expected port data after run(): IFNAME set to SSID with band/VLAN annotation
# and IFALIAS set to interface name
my %expected_ports = (
    6  => {
        IFDESCR => 'wifi0ap0',
        IFTYPE  => 71,
        IFNAME  => 'TestNet - Visitantes_2.4Ghz (2.4GHz)',
        IFALIAS => 'wifi0ap0',
    },
    10 => {
        IFDESCR => 'wifi1ap4',
        IFTYPE  => 71,
        IFNAME  => 'TestNet - Visitantes_5Ghz (5GHz)',
        IFALIAS => 'wifi1ap4',
    },
    25 => {
        IFDESCR => 'wifi1ap5.620',
        IFTYPE  => 71,
        IFNAME  => 'TestNet_Corp (5GHz, VLAN 620)',
        IFALIAS => 'wifi1ap5.620',
    },
);

# 1 cmp_deeply assertion per port + 1 NoWarnings
plan tests => scalar(keys %expected_ports) + 1;

my $snmp = GLPI::Agent::SNMP::Mock->new(
    file => "resources/walks/sample7.walk"
);
my $device = GLPI::Agent::SNMP::Device->new('snmp' => $snmp);

GLPI::Agent::SNMP::Hardware::_setGenericProperties(
    device => $device
);

my $mibsupport = GLPI::Agent::SNMP::MibSupport::Ubnt->new('device' => $device);
$mibsupport->run();

foreach my $idx (sort { $a <=> $b } keys %expected_ports) {
    my $port = $device->{PORTS}->{PORT}->{$idx};
    cmp_deeply(
        $port,
        superhashof($expected_ports{$idx}),
        "Port $idx attributes: ".join(", ", map { "$_ => $port->{$_}" } keys(%$port))
    );
}
