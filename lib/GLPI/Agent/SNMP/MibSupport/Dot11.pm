package GLPI::Agent::SNMP::MibSupport::Dot11;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See IEEE 802.11 MIB

use constant dot11DesiredSSID => '.1.2.840.10036.1.1.1.9';
use constant dot11StationID   => '.1.2.840.10036.1.1.1.1';

our $mibSupport = [
    {
        name    => "dot11",
        walkoid => dot11DesiredSSID
    }
];

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Get list of device ports
    my $ports = $device->{PORTS}->{PORT};

    # Get list of BSSID MAC addresses indexed by interface index
    my $dot11StationIDValues = $self->walk(dot11StationID) || {};
    # Get list of SSID names indexed by interface index
    my $dot11DesiredSSIDValues = $self->walk(dot11DesiredSSID) || {};

    return unless %$dot11StationIDValues && %$dot11DesiredSSIDValues;

    foreach my $index (keys(%$dot11StationIDValues)) {
        # Get BSSID MAC address for this interface index
        my $wlanMacAddress = getCanonicalMacAddress($dot11StationIDValues->{$index})
            or next;

        foreach my $port (keys(%$ports)) {
            # Only process IEEE 802.11 (WiFi) ports
            my $iftype = $device->{PORTS}->{PORT}->{$port}->{IFTYPE};
            next unless defined($iftype) && $iftype == 71;

            # Match port by MAC address
            my $ifMacAddress = $device->{PORTS}->{PORT}->{$port}->{MAC};
            next unless defined($ifMacAddress) && $ifMacAddress eq $wlanMacAddress;

            my $ifDescr = $device->{PORTS}->{PORT}->{$port}->{IFDESCR} // "";

            # Defines the port alias with the name of the radio interface (e.g. wifi0apX)
            $device->{PORTS}->{PORT}->{$port}->{IFALIAS} = $ifDescr
                unless empty($ifDescr);

            # Replaces the radio port name with its respective SSID name
            my $ifname = getCanonicalString($dot11DesiredSSIDValues->{$index});
            unless (empty($ifname)) {
                $device->{PORTS}->{PORT}->{$port}->{IFNAME} = $ifname;
            }

            last;
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Dot11 - Generic IEEE 802.11 MIB support

=head1 DESCRIPTION

This module provides generic IEEE 802.11 MIB support for all WiFi devices.
It maps BSSID MAC addresses to their respective SSID names using the standard
IEEE 802.11 MIB OIDs (dot11StationID and dot11DesiredSSID).
