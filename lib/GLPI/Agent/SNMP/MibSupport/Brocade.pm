package GLPI::Agent::SNMP::MibSupport::Brocade;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See FOUNDRY-SN-ROOT-MIB & FOUNDRY-SN-AGENT-MIB for foundry-switch

use constant    brocade   => '.1.3.6.1.4.1.1588' ;
use constant    foundry   => '.1.3.6.1.4.1.1991' ;

use constant    snChasSerNum    => brocade  .'.1.1.1.1.2.0' ;
use constant    snAgImgVer      => brocade . '.1.1.2.1.11.0' ;

# See ENTITY-MIB
use constant    entPhysicalEntry    => '.1.3.6.1.2.1.47.1.1.1.1';
use constant    entPhysicalDescr    => entPhysicalEntry . '.2';

our $mibSupport = [
    {
        name        => "brocade-switch",
        sysobjectid => getRegexpOidMatch(brocade)
    },
    {
        name        => "foundry-switch",
        sysobjectid => getRegexpOidMatch(foundry)
    }
];

sub getSerial {
    my ($self) = @_;

    return unless $self->is("foundry-switch");

    return getCanonicalString($self->get(snChasSerNum));
}

sub getModel {
    my ($self) = @_;

    return unless $self->is("brocade-switch");

    return getCanonicalString($self->get_first(entPhysicalDescr));
}

sub getFirmware {
    my ($self) = @_;

    return unless $self->is("foundry-switch");

    return getCanonicalString($self->get(snAgImgVer));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Brocade - Inventory module for Brocade Switches

=head1 DESCRIPTION

The module enhances Brocade Switches devices support.
