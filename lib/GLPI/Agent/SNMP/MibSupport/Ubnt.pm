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

our $mibSupport = [
    {
        name    => "ubnt",
        oid     => ubnt
    },
    {
        name    => "ubnt-unifi",
        sysobjectid => getRegexpOidMatch(ubnt)
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

    # Get list of device ports (e.g. raX, raiX, wifi0apX, wifi1apX etc.)
    my $ports = $device->{PORTS}->{PORT};

    # Get list of SSID
    my $unifiVapEssidValues = $self->walk(unifiVapEssid) || {};
    # Get list of Radios (e.g. ra0, rai0, wifi0ap0, wifi1ap0 etc.)
    my $unifiVapNameValues = $self->walk(unifiVapName) || {};
    # The list of Radios is co-related to the list of SSIDs
    # $unifiVapNameValues->{0} = ra0      (MediaTek-based devices)
    # $unifiVapNameValues->{0} = wifi0ap0 (Atheros-based devices)
    # $unifiVapEssidValues->{0} = <SSID>

    # UBNT-UniFi-MIB (for MediaTek-based devices with ra/rai interfaces
    # and Atheros-based devices with wifi0apX/wifi1apX interfaces)
    foreach my $port (keys(%$ports)) {
        # For each device Radio port (raX, raiX, wifi0apX, wifi1apX etc.)
        # Also handles VLAN sub-interfaces such as wifi1ap5.620 created
        # when a RADIUS server assigns a dynamic VLAN via 802.1X
        my $ifdescr = getCanonicalString($device->{PORTS}->{PORT}->{$port}->{IFDESCR});
        next unless defined($ifdescr) && $ifdescr =~ /^(?:ra\d+|rai\d+|wifi\d+ap\d+)(?:\.(\d+))?$/;

        # Replaces the port iftype from "Ethernet" (6) to "WiFi" (71)
        # UBNT APs erroneously classify WiFi interfaces as Ethernet in SNMP
        # (see https://github.com/glpi-project/glpi-agent/pull/657)
        if ($device->{PORTS}->{PORT}->{$port}->{IFTYPE} && $device->{PORTS}->{PORT}->{$port}->{IFTYPE} == 6) {
            $device->{PORTS}->{PORT}->{$port}->{IFTYPE} = 71;
        }

        # Detect VLAN sub-interfaces (e.g. wifi1ap5.620): strip the VLAN
        # suffix to obtain the parent interface name for SSID lookup
        my ($parent_ifdescr, $vlan_id);
        if ($ifdescr =~ /^(.+)\.(\d+)$/) {
            $parent_ifdescr = $1;
            $vlan_id        = $2;
        } else {
            $parent_ifdescr = $ifdescr;
        }

        foreach my $index (keys(%$unifiVapNameValues)) {
            # Compares the device's current radio port (or its parent) to the AP's radio list
            my $vapName = getCanonicalString($unifiVapNameValues->{$index});
            if ($parent_ifdescr eq $vapName) {
                # Defines the port alias with the name of the radio interface
                $device->{PORTS}->{PORT}->{$port}->{IFALIAS} = $ifdescr;
                # Replaces the radio port name with its respective <SSID>
                my $ifname = getCanonicalString($unifiVapEssidValues->{$index});

                unless (empty($ifname)) {
                    # Determine the radio frequency band from the parent interface name
                    my $band;
                    if ($parent_ifdescr =~ m/^(?:ra|wifi0ap)\d+$/) {
                        # MediaTek (ra0, ra1, ...) or Atheros (wifi0ap0, wifi0ap1, ...) 2.4GHz radio
                        $band = "2.4GHz";
                    } elsif ($parent_ifdescr =~ m/^(?:rai|wifi1ap)\d+$/) {
                        # MediaTek (rai0, rai1, ...) or Atheros (wifi1ap4, wifi1ap5, ...) 5GHz radio
                        $band = "5GHz";
                    }

                    # Annotate the SSID with band and/or VLAN ID
                    if (defined $band && defined $vlan_id) {
                        $ifname .= " ($band, VLAN $vlan_id)";
                    } elsif (defined $band) {
                        $ifname .= " ($band)";
                    } elsif (defined $vlan_id) {
                        $ifname .= " (VLAN $vlan_id)";
                    }

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
