package GLPI::Agent::SNMP::MibSupport::RNX;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant sysdescr       => '.1.3.6.1.2.1.1.1.0';

# RNX-UPDU-MIB2-MIB
use constant    rnx         => '.1.3.6.1.4.1.55108' ;
use constant    upduMib2    => rnx . '.2' ;

use constant    upduMib2PDUSerialNumber => upduMib2 . '.1.2.1.5.1' ;

use constant    upduMib2ICMFirmware     => upduMib2 . '.6.2.1.9.1' ;

our $mibSupport = [
    {
        name        => "rnx-pdu",
        sysobjectid => getRegexpOidMatch(rnx)
    }
];

sub getManufacturer {
    my ($self) = @_;

    return 'RNX';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(upduMib2PDUSerialNumber));
}

sub getModel {
    my ($self) = @_;

    my $sysdescr = getCanonicalString($self->get(sysdescr))
        or return;

    my ($model) = $sysdescr =~ /^RNX\s+(.*)\s+\(/;

    return $model;
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(upduMib2ICMFirmware));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::RNX - Inventory module for RNX Pdu devices

=head1 DESCRIPTION

The module enhances RNX Pdu devices support.
