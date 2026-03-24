#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::NoWarnings;

use GLPI::Agent::SNMP::Mock;
use GLPI::Agent::SNMP::Device;
use GLPI::Agent::SNMP::MibSupport::Ubnt;

# Port test data: index => { IFDESCR, IFTYPE, expected_IFNAME }
# Covers Atheros-based 2.4GHz (wifi0apX) interface.
# The UBNT-UniFi-MIB unifiVapName table maps VAP indices (0-7) to interface names;
# unifiVapEssid maps the same indices to SSID names.
my %port_data = (
    9  => { IFDESCR => 'wifi0ap3', IFTYPE => 71, IFNAME => 'TempSensor (2.4GHz)' },
);

# 2 assertions per port (IFNAME + IFALIAS) + 1 NoWarnings
plan tests => (scalar(keys %port_data) * 2) + 1;

my $snmp = GLPI::Agent::SNMP::Mock->new(
    file => "resources/walks/REUNIAO01.walk"
);
my $device = GLPI::Agent::SNMP::Device->new('snmp' => $snmp);

# Pre-populate device ports (normally done by NetInventory task before mibsupport runs)
foreach my $idx (keys %port_data) {
    $device->addPort(
        $idx => {
            IFDESCR => $port_data{$idx}{IFDESCR},
            IFTYPE  => $port_data{$idx}{IFTYPE},
        }
    );
}

my $mibsupport = GLPI::Agent::SNMP::MibSupport::Ubnt->new('device' => $device);
$mibsupport->run();

foreach my $idx (sort { $a <=> $b } keys %port_data) {
    my $port = $device->{PORTS}->{PORT}->{$idx};
    is(
        $port->{IFNAME},
        $port_data{$idx}{IFNAME},
        "Port $idx ($port_data{$idx}{IFDESCR}): IFNAME is '$port_data{$idx}{IFNAME}'"
    );
    is(
        $port->{IFALIAS},
        $port_data{$idx}{IFDESCR},
        "Port $idx ($port_data{$idx}{IFDESCR}): IFALIAS is '$port_data{$idx}{IFDESCR}'"
    );
}
