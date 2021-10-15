package GLPI::Agent::SNMP::MibSupport::Ricoh;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    mib2        => '.1.3.6.1.2.1' ;
use constant    enterprises => '.1.3.6.1.4.1' ;

use constant    ricoh       => enterprises . '.367.1.1' ;

use constant    hostname    => enterprises . '.367.3.2.1.6.1.1.7.1';

# Printer-MIB
use constant    printmib                => mib2 . '.43' ;
use constant    prtGeneralPrinterName   => printmib . '.5.1.1.16.1' ;

our $mibSupport = [
    {
        name        => "ricoh-printer",
        sysobjectid => getRegexpOidMatch(ricoh)
    }
];

sub getModel {
    my ($self) = @_;

    return $self->get(prtGeneralPrinterName);
}

sub getSnmpHostname {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $hostname = getCanonicalString($self->get(hostname))
        or return;

    # Don't override if found hostname is manufacturer+model
    return if $hostname eq 'RICOH '.$device->{MODEL};

    return $hostname;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Ricoh - Inventory module for Ricoh Printers

=head1 DESCRIPTION

The module enhances Ricoh printers devices support.
