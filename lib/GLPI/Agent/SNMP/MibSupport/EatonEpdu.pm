package GLPI::Agent::SNMP::MibSupport::EatonEpdu;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See EATON-EPDU-MIB

use constant    epdu     => '.1.3.6.1.4.1.534.6.6.7' ;
use constant    model    => epdu . '.1.2.1.3.0' ;
use constant    serial   => epdu . '.1.2.1.4.0' ;
use constant    firmware => epdu . '.1.2.1.5.0' ;

# See XUPS-MIB

use constant    xupsMIB => '.1.3.6.1.4.1.534.1' ;
use constant    xupsIdentManufacturer       => xupsMIB . '.1.1.0' ;
use constant    xupsIdentModel              => xupsMIB . '.1.2.0' ;
use constant    xupsIdentSoftwareVersion    => xupsMIB . '.1.3.0' ;
use constant    xupsIdentSerialNumber       => xupsMIB . '.1.6.0' ;

our $mibSupport = [
    {
        name        => 'eaton-epdu',
        sysobjectid => getRegexpOidMatch(epdu)
    },
    {
        name        => 'eaton-xups',
        sysobjectid => getRegexpOidMatch(xupsMIB)
    }
];

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(xupsIdentSerialNumber))
        if $self->is("eaton-xups");

    return $self->get(serial);
}

sub getManufacturer {
    my ($self) = @_;

    return unless $self->is("eaton-xups");

    return getCanonicalString($self->get(xupsIdentManufacturer));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(xupsIdentModel))
        if $self->is("eaton-xups");

    return $self->get(model);
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(xupsIdentSoftwareVersion))
        if $self->is("eaton-xups");

    return $self->get(firmware);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::EatonEpdu - Inventory module for Eaton ePDUs

=head1 DESCRIPTION

The module enhances Eaton ePDU devices support.
