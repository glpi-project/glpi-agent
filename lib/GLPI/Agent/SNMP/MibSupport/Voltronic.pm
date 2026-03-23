package GLPI::Agent::SNMP::MibSupport::Voltronic;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See voltronicMIB

use constant    voltronicMIB    => '.1.3.6.1.4.1.43943';

use constant    upsIdent    => voltronicMIB . '.1.1.1';
use constant    upsIdManufacturer   => upsIdent . '.1.0';
use constant    upsIdModelName      => upsIdent . '.3.0';
use constant    upsIdSerialNumber   => upsIdent . '.4.0';
use constant    upsIdFWVersion      => upsIdent . '.6.0';

our $mibSupport = [
    {
        name        => "voltronic",
        sysobjectid => getRegexpOidMatch(voltronicMIB)
    }
];

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(upsIdModelName));
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(upsIdSerialNumber));
}

sub getFirmware {
    my ($self) = @_;

    my $firmware = getCanonicalString($self->get(upsIdFWVersion));
    return if empty($firmware);

    # Cleanup
    $firmware =~ s/^VERFW://i;

    return $firmware;
}

sub getManufacturer {
    my ($self) = @_;

    return getCanonicalString($self->get(upsIdManufacturer)) || "Voltronic";
}

sub getType {
    # TODO remove when POWER is supported on server-side and replace by 'POWER'
    return 'NETWORKING';
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Voltronic - Inventory module for Voltronic based devices

=head1 DESCRIPTION

The module enhances Voltronic devices support.
