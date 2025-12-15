package GLPI::Agent::SNMP::MibSupport::Dlink;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    sysObjectID => '.1.3.6.1.2.1.1.2.0';

# Constants extracted from D-Link MIBs
use constant enterprises    => '.1.3.6.1.4.1';
use constant d_link         => enterprises . '.171';
use constant dlink_products => d_link . '.10';

our $mibSupport = [
    {
        name        => "d-link",
        sysobjectid => dlink_products
    }
];

sub _private {
    my ($self, $suboid) = @_;
    $self->{_sysobjectid} = $self->get(sysObjectID) unless $self->{_sysobjectid};
    return $self->get($self->{_sysobjectid} . $suboid);
}

sub getType {
    return 'NETWORKING';
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->_private(".1.3.0"));
}

sub getManufacturer {
    return 'D-Link';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->_private(".1.18.0"));
}

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->_private(".1.1.0"));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Handle hardware revision
    my $sysHardwareVersion = getCanonicalString($self->_private(".1.2.0"));
    unless (empty($sysHardwareVersion)) {
        my $model = $device->{MODEL} ? $device->{MODEL}." " : "";
        my $sysHardware = {
            NAME            => $model."hardware",
            DESCRIPTION     => "hardware revision",
            TYPE            => "device",
            VERSION         => $sysHardwareVersion,
            MANUFACTURER    => "D-Link"
        };

        $device->addFirmware($sysHardware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Dlink - Inventory module for D-Link switches

=head1 DESCRIPTION

The module enhances support for D-Link devices
