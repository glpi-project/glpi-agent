package GLPI::Agent::SNMP::MibSupport::Brocade;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    brocade   => '.1.3.6.1.4.1.1991' ;
use constant    serial  => brocade  .'.1.1.1.1.2.0' ;
use constant    fw_pri => brocade . '.1.1.2.1.11.0' ;

our $mibSupport = [
    {
        name        => "brocade-switch",
        sysobjectid => getRegexpOidMatch(brocade)
    }
];

sub getSerial {
    my ($self) = @_;

    return $self->get(serial);
}


sub getFirmware {
    my ($self) = @_;

    return $self->get(fw_pri);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Brocade - Inventory module for Brocade Switches

=head1 DESCRIPTION

The module enhances Brocade Switches devices support.
