package GLPI::Agent::SNMP::MibSupport::Lexmark;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    enterprises => '.1.3.6.1.4.1';

# LEXMARK-ROOT-MIB
use constant    lexmark => enterprises . '.641';

# LEXMARK-PVT-MIB
use constant    printer => lexmark . '.2';

use constant    prtgenInfoEntry => printer . '1.2.1';

use constant    prtgenPrinterName   => prtgenInfoEntry . '.2.1' ;
use constant    prtgenCodeRevision  => prtgenInfoEntry . '.4.1' ;
use constant    prtgenSerialNo      => prtgenInfoEntry . '.6.1' ;

# LEXMARK-MPS-MIB
use constant    mps => lexmark . '.6' ;

use constant    device      => mps . '.2';
use constant    inventory   => mps . '.3';

# OID name for the 2 following are extrapolated
use constant    deviceModel     => device . '.3.1.4.1';
use constant    deviceSerial    => device . '.3.1.5.1';

use constant    hwInventorySerialNumber => inventory . '.1.1.7.1.1';
use constant    swInventoryRevision     => inventory . '.3.1.7.1.1' ;

# Printer-MIB
use constant    prtGeneralSerialNumber  => '.1.3.6.1.2.1.43.5.1.1.17.1';

# HOST-RESOURCES-MIB
use constant    hrDeviceDescr   => '.1.3.6.1.2.1.25.3.2.1.3.1';

our $mibSupport = [
    {
        name        => "lexmark-printer",
        sysobjectid => getRegexpOidMatch(lexmark)
    }
];

sub getModel {
    my ($self) = @_;

    my $model;
    foreach my $oid (deviceModel, prtgenPrinterName) {
        $model = getCanonicalString($self->get($oid))
            and last;
    }

    unless ($model) {
        $model = getCanonicalString($self->get(hrDeviceDescr))
            or return;
        ($model) = $model =~ /^(Lexmark\s+\S+)/;
    }

    return unless $model;

    # Strip manufacturer
    $model =~ s/^Lexmark\s+//i;

    return $model;
}

sub getFirmware {
    my ($self) = @_;

    my $firmware;
    foreach my $oid (swInventoryRevision, prtgenCodeRevision) {
        $firmware = getCanonicalString($self->get($oid))
            and last;
    }

    return $firmware;
}

sub getSerial {
    my ($self) = @_;

    my $serial;
    foreach my $oid (prtGeneralSerialNumber, deviceSerial, prtgenSerialNo) {
        $serial = getCanonicalString($self->get($oid))
            and last;
    }

    return $serial;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Lexmark - Inventory module for Lexmark Printers

=head1 DESCRIPTION

The module enhances Lexmark printers devices support.
