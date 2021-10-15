package GLPI::Agent::SNMP::MibSupport::Zebra;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See ESI-MIB

use constant    esi     => '.1.3.6.1.4.1.683' ;
use constant    model2  => esi . '.6.2.3.2.1.15.1' ;
use constant    serial  => esi . '.1.5.0' ;
use constant    fw2     => esi . '.1.9.0' ;

# See ZEBRA-QL-MIB

use constant    zebra   => '.1.3.6.1.4.1.10642' ;
use constant    model1  => zebra . '.1.1.0' ;
use constant    fw1     => zebra . '.1.2.0' ;

use constant    zql_zebra_ql    => zebra . '.200' ;
use constant    model3  => zql_zebra_ql . '.19.7.0' ;
use constant    serial3 => zql_zebra_ql . '.19.5.0' ;

our $mibSupport = [
    {
        name        => "zebra-printer",
        sysobjectid => getRegexpOidMatch(esi)
    }
];

sub getSerial {
    my ($self) = @_;

    # serial3 is more accurate than serial on GK420 & ZE500
    return hex2char($self->get(serial3) || $self->get(serial));
}

sub getModel {
    my ($self) = @_;

    return hex2char($self->get(model1) || $self->get(model2) || $self->get(model3));
}

sub getFirmware {
    my ($self) = @_;

    return hex2char($self->get(fw1) || $self->get(fw2));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Zebra - Inventory module for Zebra Printers

=head1 DESCRIPTION

The module enhances Zebra printers devices support.
