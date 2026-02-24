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
use constant    upduMib2PDUPartNumber   => upduMib2 . '.1.2.1.6.1' ;

use constant    upduMib2ICMFirmware     => upduMib2 . '.6.2.1.9.1' ;

use constant    upduMib2Outlet      => upduMib2 . '.9' ;
use constant    upduMib2OutletEntry => upduMib2Outlet . '.2.1';

use constant    upduMib2OutletSystemName    => upduMib2OutletEntry . '.2';
use constant    upduMib2OutletCustomName    => upduMib2OutletEntry . '.3';
use constant    upduMib2OutletRating        => upduMib2OutletEntry . '.8';

our $mibSupport = [
    {
        name        => "rnx-pdu",
        sysobjectid => getRegexpOidMatch(rnx)
    }
];

sub getType {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # From GLPI 12.0.0, this device can be reported as PDU
    my $glpi_version = $device->{glpi} ? glpiVersion($device->{glpi}) : 0;
    return $glpi_version && $glpi_version >= glpiVersion('12.0.0') ?
        "PDU" : "NETWORKING";
}

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

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # PDU support
    if ($device->{TYPE} && $device->{TYPE} eq "PDU") {

        my %ratingType = qw(
            10000   C13
            16000   C19
        );

        my @plugs;

        my $systemName = $self->walk(upduMib2OutletSystemName);
        if ($systemName) {
            my $customNames = $self->walk(upduMib2OutletCustomName);
            my $rating = $self->walk(upduMib2OutletRating);

            foreach my $key (sort { $a <=> $b } keys(%{$systemName})) {
                push @plugs, {
                    NAME    => getCanonicalString($customNames->{$key}) // getCanonicalString($systemName->{$key}),
                    NUMBER  => $key,
                    TYPE    => $ratingType{$rating->{$key}} // "unknown",
                };
            }
        }
        $device->{PDU}->{PLUGS} = \@plugs if @plugs;

        my $pduPartNumber = getCanonicalString($self->get(upduMib2PDUPartNumber));
        $device->{PDU}->{TYPE} = $pduPartNumber if $pduPartNumber;
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::RNX - Inventory module for RNX Pdu devices

=head1 DESCRIPTION

The module enhances RNX Pdu devices support.
