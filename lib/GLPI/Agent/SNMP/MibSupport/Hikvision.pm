package GLPI::Agent::SNMP::MibSupport::Hikvision;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See Hikvision-MIB

use constant hikvision  => '.1.3.6.1.4.1.39165';
use constant hikvisionModel   => hikvision . '.1.1.0';
use constant hikvisionMac  => hikvision . '.1.4.0';

our $mibSupport = [
    {
        name    => "hikvision",
        sysobjectid => getRegexpOidMatch(hikvision)
    },{
        name    => "hikvision-model",
        privateoid => hikvisionModel
    },
];

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    return 'Hikvision';
}

sub getSerial {
    my ($self) = @_;

    my $serial = getCanonicalString($self->get(hikvisionMac))
        or return;
    $serial =~ s/-//g;

    return $serial;
}

sub getMacAddress {
    my ($self) = @_;

    my $mac = getCanonicalString($self->get(hikvisionMac))
        or return;
    $mac =~ s/-/:/g;

    return getCanonicalMacAddress($mac);
}

sub getSnmpHostname {
    my ($self) = @_;

    my $serial = $self->getSerial()
        or return;

    my $device = $self->device
        or return;

    return $device->{MODEL}.'_'.$serial;
}

sub getModel {
    my ($self) = @_;

    return $self->get(hikvisionModel);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Hikvision - Inventory module for Hikvision

=head1 DESCRIPTION

This module enhances Hikvision devices support.
