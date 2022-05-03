package GLPI::Agent::SNMP::MibSupport::DefencePro;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant defencepro             => '.1.3.6.1.4.1.89';
use constant model                  => defencepro . '.2.14.0';
use constant rndSerialNumber        => defencepro . '.2.12.0';
use constant rsWSDUserVersion       => defencepro . '.35.1.34';
use constant rsWSDSysBaseMACAddress => defencepro . '.35.1.69.5.0';

our $mibSupport = [
    {
        name        => "DefencePro",
        sysobjectid => getRegexpOidMatch(defencepro)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(rsWSDUserVersion));
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(rndSerialNumber));
}

sub getMacAddress {
    my ($self) = @_;

    return getCanonicalMacAddress($self->get(rsWSDSysBaseMACAddress));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(model));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::DefencePro - Inventory module for DefencePro appliance

=head1 DESCRIPTION

This module enhances DefencePro appliances support.
