package GLPI::Agent::SNMP::MibSupport::Ubnt;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See UBNT-MIB

use constant ubnt               => '.1.3.6.1.4.1.41112';
use constant ubntWlStatApMac    => ubnt . '.1.4.5.1.4.1';

# See UBNT-UniFi-MIB

use constant unifiVapEssid        => ubnt . '.1.6.1.2.1.6';
use constant unifiVapName         => ubnt . '.1.6.1.2.1.7';
use constant unifiApSystemVersion => ubnt . '.1.6.3.6.0';
use constant unifiApSystemModel   => ubnt . '.1.6.3.3.0';

# See IEEE 802.11 MIB

use constant dot11DesiredSSID => '.1.2.840.10036.1.1.1.9';
use constant dot11StationID   => '.1.2.840.10036.1.1.1.1';

our $mibSupport = [
    {
        name    => "ubnt",
        oid     => ubnt
    },
    {
        name    => "ubnt-unifi",
        sysobjectid => getRegexpOidMatch(ubnt)
    },
    {
        name        => "ubnt-dot11",
        sysobjectid => getRegexpOidMatch(ubnt),
        oid         => '.1.2.840.10036'
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(unifiApSystemVersion));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(unifiApSystemModel));
}

sub getSerial {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $serial = getCanonicalMacAddress($self->get(ubntWlStatApMac)) || $device->{MAC};
    $serial =~ s/://g;

    return $serial;
}

sub getMacAddress {
    my ($self) = @_;

    return getCanonicalMacAddress($self->get(ubntWlStatApMac));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Get list of device ports (e.g. raX, raiX etc.)
    my $ports = $device->{PORTS}->{PORT};

    # Get list of SSID
    my $unifiVapEssidValues = $self->walk(unifiVapEssid) || {};
    # Get list of Radios (e.g. ra0, rai0 etc.)
    my $unifiVapNameValues = $self->walk(unifiVapName) || {};
    # The list of Radios is co-related to the list of SSIDs
    # $unifiVapNameValues->{0} = ra0
    # $unifiVapEssidValues->{0} = <SSID>

    if (%$unifiVapEssidValues) {
        # Primary method: UBNT-UniFi-MIB (for MediaTek-based devices with ra/rai interfaces)
        foreach my $port (keys(%$ports)) {
            # For each device Radio port (raX, raiX etc.)
            # If you have more than one SSID there will also be more raX, raiX for each SSID.
            my $ifdescr = $device->{PORTS}->{PORT}->{$port}->{IFDESCR};
            next unless defined($ifdescr) && $ifdescr =~ /^ra/;

            # Replaces the port iftype from "Ethernet" (6) to "WiFi" (71)
            if ($device->{PORTS}->{PORT}->{$port}->{IFTYPE} && $device->{PORTS}->{PORT}->{$port}->{IFTYPE} == 6) {
                $device->{PORTS}->{PORT}->{$port}->{IFTYPE} = 71;
            }

            foreach my $index (keys(%$unifiVapNameValues)) {
                # Compares the device's current radio port name to the AP's radio list (e.g. raX eq raX)
                if ($ifdescr eq $unifiVapNameValues->{$index}) {
                    # Defines the port alias with the name of the radio (e.g. raX)
                    $device->{PORTS}->{PORT}->{$port}->{IFALIAS} = $ifdescr;
                    # Replaces the radio port name with its respective <SSID>
                    my $ifname = getCanonicalString($unifiVapEssidValues->{$index});

                    unless (empty($ifname)) {
                        # raX and raiX are the network interfaces for the 2.4GHz and 5GHz radios respectively
                        if ($ifdescr =~ m/^ra\d+$/) {
                            $ifname .= " (2.4GHz)";
                        } elsif ($ifdescr =~ m/^rai\d+$/) {
                            $ifname .= " (5GHz)";
                        }

                        $device->{PORTS}->{PORT}->{$port}->{IFNAME} = $ifname;
                    }

                    last;
                }
            }
        }
    } else {
        # Fallback method: IEEE 802.11 MIB (for Qualcomm-based devices like UAP-AC-Lite)
        # which use wifi0apX / wifi1apX interface naming and do not expose UBNT-UniFi-MIB OIDs

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
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Ubnt - Inventory module for Ubnt

=head1 DESCRIPTION

This module enhances Ubnt devices support.
