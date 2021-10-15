package GLPI::Agent::SNMP::MibSupport::Oki;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant oki    => '.1.3.6.1.4.1.2001';
use constant model  => oki . '.1.1.1.1.11.1.10.25.0';
use constant serial => oki . '.1.1.1.1.11.1.10.45.0';

our $mibSupport = [
    {
        name        => "oki",
        sysobjectid => getRegexpOidMatch(oki)
    }
];

sub getSerial {
    my ($self) = @_;

    return $self->get(serial);
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(model));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Oki - Inventory module for Oki printers

=head1 DESCRIPTION

This module enhances Oki printers support.
