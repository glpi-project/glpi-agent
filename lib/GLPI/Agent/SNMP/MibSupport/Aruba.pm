package GLPI::Agent::SNMP::MibSupport::Aruba;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See Q-BRIDGE-MIB
use constant    dot1qTpFdbStatus => '.1.3.6.1.2.1.17.7.1.2.2.1.3';

# See ARUBA-MIB
use constant    aruba   => '.1.3.6.1.4.1.14823' ;

# See AI-AP-MIB
use constant    aiMIB   => aruba . '.2.3.3.1' ;

use constant    aiVirtualControllerVersion  => aiMIB . '.1.4.0';
use constant    aiAPSerialNum               => aiMIB . '.2.1.1.4';
use constant    aiAPModelName               => aiMIB . '.2.1.1.6';
use constant    aiWlanESSID                 => aiMIB . '.2.3.1.3';
use constant    aiWlanMACAddress            => aiMIB . '.2.3.1.4';

our $mibSupport = [
    {
        name        => "aruba",
        sysobjectid => getRegexpOidMatch(aruba)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(aiVirtualControllerVersion));
}

sub _this {
    my ($self) = @_;

    unless ($self->{_this}) {
        # Find reference to our device
        my $dot1qTpFdbStatus = $self->walk(dot1qTpFdbStatus);
        if ($dot1qTpFdbStatus) {
            my ($subkey) = first {
                $dot1qTpFdbStatus->{$_} eq '4' } keys(%{$dot1qTpFdbStatus});
            unless (empty($subkey)) {
                my ($extracted) = $subkey =~ /^\d+\.(.*)$/;
                $self->{_this} = $extracted unless empty($extracted);
            }
        }
    }

    return $self->{_this};
}

sub getSerial {
    my ($self) = @_;

    my $this = $self->_this
        or return;

    return getCanonicalString($self->get(aiAPSerialNum.'.'.$this));
}

sub getModel {
    my ($self) = @_;

    my $this = $self->_this;
    if ($this) {
        my $model = getCanonicalString($self->get(aiAPModelName.'.'.$this));
        return "AP $model" if $model;
    }

    my $device = $self->device
        or return;

    my $model;

    # Extract model from device description for ArubaOS based systems
    ( $model ) = $device->{DESCRIPTION} =~ /^ArubaOS\s+\(MODEL:\s*(.*)\)/
        if $device->{DESCRIPTION};

    return unless $model;

    return "AP $model";
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Get list of device ports (e.g. radioX_ssid_idY)
    my $ports = $device->{PORTS}->{PORT};

    # Equivalent to "show ap bss-table" Aruba IAP CLI output command:

    # Get list of SSID
    my $aiWlanESSIDValues = $self->walk(aiWlanESSID) || {};
    # Get list of Radios (e.g. radioX_ssid_idY etc.)
    my $aiWlanMACAddressValues = $self->walk(aiWlanMACAddress) || {};
    # The list of Radios is co-related to the list of SSIDs
    # $aiWlanMACAddressValues->{0} = radio0_ssid_id0
    # $aiWlanESSIDValues->{0} = <SSID>

    foreach my $index (keys(%$aiWlanMACAddressValues)) {
        # Get WLAN BSSID (e.g. XX:XX:XX:XX:XX:XX)
        my $wlanMacAddress = getCanonicalMacAddress($aiWlanMACAddressValues->{$index})
            or next;

        foreach my $port (keys(%$ports)) {
            my $ifMacAddress = $device->{PORTS}->{PORT}->{$port}->{MAC};
            next unless defined($ifMacAddress) && $ifMacAddress eq $wlanMacAddress;

            my $ifDescr = $device->{PORTS}->{PORT}->{$port}->{IFDESCR} // "";

            # Defines the port alias with the name of the radio (e.g. radioX_ssid_idY)
            $device->{PORTS}->{PORT}->{$port}->{IFALIAS} = $ifDescr
                unless empty($ifDescr);
            # Replaces the radio port name with its respective <SSID>
            my $ifName = getCanonicalString($aiWlanESSIDValues->{$index});
            unless (empty($ifName)) {
                # radio0 and radio1 are the network interfaces for the 5GHz and 2.4GHz radios respectively
                if ($ifDescr =~ m/^radio0/) {
                    $ifName .= " (5GHz)";
                } elsif ($ifDescr =~ m/^radio1/) {
                    $ifName .= " (2.4GHz)";
                }

                $device->{PORTS}->{PORT}->{$port}->{IFNAME} = $ifName;
            }
            last;
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Aruba - Inventory module for Aruba AP

=head1 DESCRIPTION

The module enhances Aruba wifi access point devices support.
