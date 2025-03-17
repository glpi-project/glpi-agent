package GLPI::Agent::SNMP::MibSupport::Raritan;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    raritan => '.1.3.6.1.4.1.13742' ;
use constant    pdu2    => raritan . '.6' ;

use constant    nameplateEntry  => pdu2 . '.3.2.1.1';
use constant    pduManufacturer => nameplateEntry . '.2.1';
use constant    pduModel        => nameplateEntry . '.3.1';
use constant    pduSerialNumber => nameplateEntry . '.4.1';

use constant    unitConfigurationEntry  => pdu2 . '.3.2.2.1';
use constant    pduName                 => unitConfigurationEntry . '.13.1';

our $mibSupport = [
    {
        name        => "raritan-pdu2",
        sysobjectid => getRegexpOidMatch(pdu2)
    }
];

sub getManufacturer {
    my ($self) = @_;

    return getCanonicalString($self->get(pduManufacturer)) || 'Raritan';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(pduSerialNumber));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(pduModel));
}

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(pduName));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Raritan - Inventory module for Raritan Pdu devices

=head1 DESCRIPTION

The module enhances Raritan Pdu devices support.
