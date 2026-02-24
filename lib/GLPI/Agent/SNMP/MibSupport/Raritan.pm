package GLPI::Agent::SNMP::MibSupport::Raritan;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    raritan => '.1.3.6.1.4.1.13742' ;
use constant    pdu2    => raritan . '.6' ;

use constant    configuration   => pdu2 . '.3';

use constant    unit    => configuration . '.2';

use constant    nameplateEntry  => unit . '.1.1';
use constant    pduManufacturer => nameplateEntry . '.2.1';
use constant    pduModel        => nameplateEntry . '.3.1';
use constant    pduSerialNumber => nameplateEntry . '.4.1';
use constant    pduRatedCurrent => nameplateEntry . '.6.1';

use constant    unitConfigurationEntry  => unit . '.2.1';
use constant    pduName                 => unitConfigurationEntry . '.13.1';

use constant    outlet  => configuration . '.5';
use constant    outletLabel                 => outlet . '.3.1.2';
use constant    outletName                  => outlet . '.3.1.3';
use constant    outletReceptacleDescriptor  => outlet . '.3.1.29';

our $mibSupport = [
    {
        name        => "raritan-pdu2",
        sysobjectid => getRegexpOidMatch(pdu2)
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

    return getCanonicalString($self->get(pduManufacturer)) || 'Raritan';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(pduSerialNumber));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(pduModel));
}

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(pduName));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # PDU support
    if ($device->{TYPE} && $device->{TYPE} eq "PDU") {

        my @plugs;

        my $labels = $self->walk(outletLabel);
        if ($labels) {
            my $names = $self->walk(outletName);
            my $descriptors = $self->walk(outletReceptacleDescriptor);

            foreach my $key (sort { _oidkeyorder($a) <=> _oidkeyorder($b) } keys(%{$labels})) {
                my $descriptor = getCanonicalString($descriptors->{$key}) // '';
                push @plugs, {
                    NAME    => getCanonicalString($names->{$key} // $labels->{$key}),
                    NUMBER  => getCanonicalString($labels->{$key}),
                    TYPE    => $descriptor,
                };
            }
        }
        $device->{PDU}->{PLUGS} = \@plugs if @plugs;

        my $ratedCurrent = getCanonicalString($self->get(pduRatedCurrent));
        $device->{PDU}->{TYPE} = $ratedCurrent if $ratedCurrent;
    }
}

sub _oidkeyorder {
    my $index = shift;
    $index =~ s/[.]//;
    return int($index);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Raritan - Inventory module for Raritan Pdu devices

=head1 DESCRIPTION

The module enhances Raritan Pdu devices support.
