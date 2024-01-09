package GLPI::Agent::SNMP::MibSupport::Ricoh;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    mib2        => '.1.3.6.1.2.1' ;
use constant    enterprises => '.1.3.6.1.4.1' ;

# Ricoh-Private-MIB
use constant    ricoh       => enterprises . '.367';

use constant    ricohAgentsID   => ricoh . '.1.1' ;
use constant    ricohNetCont    => ricoh . '.3.2.1.6' ;

use constant    ricohEngCounter => ricoh . '.3.2.1.2.19' ;
use constant    ricohEngCounterType     => ricohEngCounter . '.5.1.2';
use constant    ricohEngCounterValue    => ricohEngCounter . '.5.1.9';

use constant    hostname        => ricohNetCont . '.1.1.7.1';

# Printer-MIB
use constant    printmib                => mib2 . '.43' ;
use constant    prtGeneralPrinterName   => printmib . '.5.1.1.16.1' ;

our $mibSupport = [
    {
        name        => "ricoh-printer",
        sysobjectid => getRegexpOidMatch(ricohAgentsID)
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

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $types = $self->walk(ricohEngCounterType);
    if ($types) {
        my $counters = $self->walk(ricohEngCounterValue) // {};

        my %mapping = (
            10  => 'TOTAL',
            200 => 'COPYTOTAL',
            201 => 'COPYBLACK',
            202 => 'COPYCOLOR',
            203 => 'COPYCOLOR',
            300 => 'FAXTOTAL',
            400 => 'PRINTTOTAL',
            401 => 'PRINTBLACK',
            402 => 'PRINTCOLOR',
            403 => 'PRINTCOLOR',
            870 => 'SCANNED',
            871 => 'SCANNED',
        );

        my %add_mapping = map { $_ => 1 } (202, 203, 402, 403, 870, 871);

        foreach my $index (sort keys(%{$types})) {
            my $type  = $types->{$index};
            my $counter = $mapping{$type}
                or next;
            my $count = $counters->{$index}
                or next;
            if ($add_mapping{$type} && $device->{PAGECOUNTERS}->{$counter}) {
                $device->{PAGECOUNTERS}->{$counter} += $count;
            } else {
                $device->{PAGECOUNTERS}->{$counter} = $count;
            }
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Ricoh - Inventory module for Ricoh Printers

=head1 DESCRIPTION

The module enhances Ricoh printers devices support.
