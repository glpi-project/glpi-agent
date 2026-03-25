#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep qw(cmp_deeply);
use Test::NoWarnings;

use GLPI::Agent::SNMP::Mock;
use GLPI::Agent::SNMP::Device;
use GLPI::Agent::SNMP::MibSupport::Ubnt;

# Initial port data for seeding (before run): UBNT APs erroneously report
# WiFi interfaces as Ethernet (IFTYPE=6) via SNMP.
my %initial_ports = (
    6  => { IFDESCR => 'wifi0ap0',      IFTYPE => 6 },
    10 => { IFDESCR => 'wifi1ap4',      IFTYPE => 6 },
    11 => { IFDESCR => 'wifi1ap5.620',  IFTYPE => 6 },
);

# Expected port data after run(): IFTYPE corrected to 71 (WiFi),
# IFNAME set to SSID with band/VLAN annotation, IFALIAS set to interface name.
my %expected_ports = (
    6  => {
        IFDESCR => 'wifi0ap0',
        IFTYPE  => 71,
        IFNAME  => 'TestNet - Visitantes_2.4GHz (2.4GHz)',
        IFALIAS => 'wifi0ap0',
    },
    10 => {
        IFDESCR => 'wifi1ap4',
        IFTYPE  => 71,
        IFNAME  => 'TestNet - Visitantes_5GHz (5GHz)',
        IFALIAS => 'wifi1ap4',
    },
    11 => {
        IFDESCR => 'wifi1ap5.620',
        IFTYPE  => 71,
        IFNAME  => 'TestNet_Corp (5GHz, VLAN 620)',
        IFALIAS => 'wifi1ap5.620',
    },
);

# 1 cmp_deeply assertion per port + 1 NoWarnings
plan tests => scalar(keys %expected_ports) + 1;

my $snmp = GLPI::Agent::SNMP::Mock->new(
    file => "resources/walks/sample07.walk"
);
my $device = GLPI::Agent::SNMP::Device->new('snmp' => $snmp);

# Pre-populate device ports (normally done by NetInventory task before mibsupport runs)
foreach my $idx (keys %initial_ports) {
    $device->addPort(
        $idx => {
            IFDESCR => $initial_ports{$idx}{IFDESCR},
            IFTYPE  => $initial_ports{$idx}{IFTYPE},
        }
    );
}

my $mibsupport = GLPI::Agent::SNMP::MibSupport::Ubnt->new('device' => $device);
$mibsupport->run();

foreach my $idx (sort { $a <=> $b } keys %expected_ports) {
    my $port = $device->{PORTS}->{PORT}->{$idx};
    cmp_deeply(
        $port,
        $expected_ports{$idx},
        "Port $idx doesn't match expected values: ".join(", ", map { "$_ => $port->{$_}" } keys(%$port))
    );
}
