package FusionInventory::Agent::SNMP::MibSupport::Multitech;

use strict;
use warnings;

use parent 'FusionInventory::Agent::SNMP::MibSupportTemplate';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::SNMP;

use constant multiTech  => '.1.3.6.1.4.1.995';

use constant mtsRouterSystemObjects => multiTech . '.15.1.1';

use constant mtsRouterSystemModelId         => mtsRouterSystemObjects . '.1.0';
use constant mtsRouterSystemSerialNumber    => mtsRouterSystemObjects . '.2.0';
use constant mtsRouterSystemFirmware        => mtsRouterSystemObjects . '.3.0';

# Multitech modules do not support standard MIBs and then won't provide sysObjectID
# and no hostname.
# Detection is based on a private OID availability.
# Hostname is then computed from model and serial number.

our $mibSupport = [
    {
        name        => "multitech",
        privateoid  => mtsRouterSystemModelId,
    }
];

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(mtsRouterSystemSerialNumber));
}

sub getSnmpHostname {
    my ($self) = @_;

    my $serial = $self->getSerial()
        or return;

    return $self->{MODEL}.'_'.$serial;
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(mtsRouterSystemModelId));
}

sub getFirmware {
    my ($self) = @_;

    return $self->get(mtsRouterSystemFirmware);
}

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    return 'Multitech';
}

1;

__END__

=head1 NAME

FusionInventory::Agent::SNMP::MibSupport::Multitech - Inventory module for MultiTech

=head1 DESCRIPTION

This module provides MultiTech products support.
