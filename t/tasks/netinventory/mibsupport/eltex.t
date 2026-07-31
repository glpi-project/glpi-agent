#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::NoWarnings;

use GLPI::Agent::SNMP::Mock;
use GLPI::Agent::SNMP::Device;
use GLPI::Agent::SNMP::Hardware;
use GLPI::Agent::SNMP::MibSupport::Eltex;

plan tests => 8;

my $snmp = GLPI::Agent::SNMP::Mock->new(
    file => "resources/walks/eltex_mes2348b.walk"
);
my $device = GLPI::Agent::SNMP::Device->new('snmp' => $snmp);

GLPI::Agent::SNMP::Hardware::_setGenericProperties(
    device => $device
);

my $ports = $device->{PORTS}->{PORT};

# Before run(): phantom ports built from dot3StatsDuplexStatus rows that have no
# matching ifTable interface only carry an IFPORTDUPLEX value
is(scalar(keys %{$ports}), 5, "five ports built before run()");
ok(!defined($ports->{157}->{IFNUMBER}), "port 157 is a phantom (no IFNUMBER)");
is($ports->{157}->{IFPORTDUPLEX}, 1, "phantom port 157 only carries duplex value");

my $mibsupport = GLPI::Agent::SNMP::MibSupport::Eltex->new('device' => $device);
$mibsupport->run();

# After run(): only the real ifTable interfaces remain
is(scalar(keys %{$ports}), 2, "phantom ports removed after run()");
is($ports->{49}->{IFNAME}, "gi1/0/1", "real port 49 kept");
is($ports->{49}->{IFPORTDUPLEX}, 3, "real port duplex value preserved");
ok(!exists $ports->{157}, "phantom port 157 removed");
