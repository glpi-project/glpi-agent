package GLPI::Agent::SNMP::MibSupport::Dot11;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See IEEE 802.11 MIB

use constant dot11DesiredSSID => '.1.2.840.10036.1.1.1.9';

our $mibSupport = [
    {
        name    => "dot11",
        oid     => '.1.2.840.10036'
    }
];

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Get list of device ports
    my $ports = $device->{PORTS}->{PORT};
    return unless $ports;

    # Get list of SSID names indexed by interface index
    my $dot11DesiredSSIDValues = $self->walk(dot11DesiredSSID) || {};
    return unless %$dot11DesiredSSIDValues;

    foreach my $index (keys(%$dot11DesiredSSIDValues)) {
        # The IEEE 802.11 MIB uses the same ifIndex as the IF-MIB, so we can
        # look up the port directly by interface index without MAC matching
        my $port = $ports->{$index}
            or next;

        # Only process IEEE 802.11 (WiFi) ports
        next unless defined($port->{IFTYPE}) && $port->{IFTYPE} == 71;

        my $ifDescr = $port->{IFDESCR} // "";

        # Defines the port alias with the name of the radio interface (e.g. wifi0apX)
        $port->{IFALIAS} = $ifDescr
            unless empty($ifDescr);

        # Replaces the radio port name with its respective SSID name
        # (only if no vendor-specific module has already set a richer value)
        my $ifname = getCanonicalString($dot11DesiredSSIDValues->{$index});
        $port->{IFNAME} = $ifname unless empty($ifname) || defined($port->{IFNAME});
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Dot11 - Generic IEEE 802.11 MIB support

=head1 DESCRIPTION

This module provides generic IEEE 802.11 MIB support for all WiFi devices.
It maps interface SSID names using the standard IEEE 802.11 MIB OID
(dot11DesiredSSID) via direct ifIndex lookup, which works for both SNMPWalk
files and live SNMP scans.
