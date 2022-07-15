package GLPI::Agent::SNMP::MibSupport::Idrac;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant idrac  => '.1.3.6.1.4.1.674.10892';
use constant serial => idrac . '.2.1.1.11.0';

our $mibSupport = [
    {
        name        => "idrac",
        sysobjectid => getRegexpOidMatch(idrac)
    }
];

sub getSerial {
    my ($self) = @_;

    return $self->get(serial);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Idrac - Inventory module for Idrac

=head1 DESCRIPTION

This module enhances Idrac support.
