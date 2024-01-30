package GLPI::Agent::SNMP::MibSupport::Pantum;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    mib2        => '.1.3.6.1.2.1' ;
use constant    enterprises => '.1.3.6.1.4.1' ;

# Pantum private
use constant    pantum  => enterprises . '.40093';

use constant    pantumPrinter   => pantum . '.1.1' ;
use constant    pantumSerialNumber1 => pantumPrinter . '.1.5' ;
use constant    pantumSerialNumber2 => pantum . '.6.1.2' ;
use constant    pantumSerialNumber3 => pantum . '.10.1.1.4' ;

# Printer-MIB
use constant    printmib                => mib2 . '.43' ;
use constant    prtGeneralPrinterName   => printmib . '.5.1.1.16.1' ;

our $mibSupport = [
    {
        name        => "pantum-printer",
        sysobjectid => getRegexpOidMatch(pantumPrinter)
    }
];

sub getModel {
    my ($self) = @_;

    return $self->get(prtGeneralPrinterName);
}

sub getSerial {
    my ($self) = @_;

    return $self->get(pantumSerialNumber1) || $self->get(pantumSerialNumber2) ||
        $self->get(pantumSerialNumber3);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Pantum - Inventory module for Pantum Printers

=head1 DESCRIPTION

The module enhances Pantum printers devices support.
