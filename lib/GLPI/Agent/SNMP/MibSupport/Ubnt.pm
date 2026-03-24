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

    if (%$unifiVapEssidValues) {
        # UBNT-UniFi-MIB (for MediaTek-based devices with ra/rai interfaces
        # and Atheros-based devices with wifi0apX/wifi1apX interfaces)
        foreach my $port (keys(%$ports)) {
            # For each device Radio port (raX, raiX, wifi0apX, wifi1apX etc.)
            # If you have more than one SSID there will also be more interfaces for each SSID.
            my $ifdescr = $device->{PORTS}->{PORT}->{$port}->{IFDESCR};
            next unless defined($ifdescr) && $ifdescr =~ /^(?:ra|wifi\d+ap)/;

            # Replaces the port iftype from "Ethernet" (6) to "WiFi" (71)
            if ($device->{PORTS}->{PORT}->{$port}->{IFTYPE} && $device->{PORTS}->{PORT}->{$port}->{IFTYPE} == 6) {
                $device->{PORTS}->{PORT}->{$port}->{IFTYPE} = 71;
            }

            foreach my $index (keys(%$unifiVapNameValues)) {
                # Compares the device's current radio port name to the AP's radio list
                if ($ifdescr eq $unifiVapNameValues->{$index}) {
                    # Defines the port alias with the name of the radio interface
                    $device->{PORTS}->{PORT}->{$port}->{IFALIAS} = $ifdescr;
                    # Replaces the radio port name with its respective <SSID>
                    my $ifname = getCanonicalString($unifiVapEssidValues->{$index});

                    unless (empty($ifname)) {
                        # Annotate the SSID with the radio frequency band
                        if ($ifdescr =~ m/^(?:ra|wifi0ap)\d+$/) {
                            # MediaTek (ra0, ra1, ...) or Atheros (wifi0ap0, wifi0ap1, ...) 2.4GHz radio
                            $ifname .= " (2.4GHz)";
                        } elsif ($ifdescr =~ m/^(?:rai|wifi1ap)\d+$/) {
                            # MediaTek (rai0, rai1, ...) or Atheros (wifi1ap4, wifi1ap5, ...) 5GHz radio
                            $ifname .= " (5GHz)";
                        }

                        $device->{PORTS}->{PORT}->{$port}->{IFNAME} = $ifname;
                    }

                    last;
                }
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
