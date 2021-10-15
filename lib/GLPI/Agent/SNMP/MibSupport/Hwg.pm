package GLPI::Agent::SNMP::MibSupport::Hwg;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See Hwg-MIB

use constant hwg        => '.1.3.6.1.4.1.21796';
use constant hwgModel   => '.1.3.6.1.2.1.1.1.0';
use constant hwgWldMac  => hwg . '.4.5.70.1.0';
use constant hwgSteMac  => hwg . '.4.1.70.1.0';
use constant hwgSte2Mac  => hwg . '.4.9.70.1.0';

our $mibSupport = [
    {
        name    => "hwg",
        sysobjectid => getRegexpOidMatch(hwg)
    }
];

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    return 'HW group s.r.o';
}

sub getSerial {
    my ($self) = @_;

    my $serial = getCanonicalMacAddress(getCanonicalString($self->get(hwgWldMac) || $self->get(hwgSteMac)  || $self->get(hwgSte2Mac)));
    $serial =~ s/://g;

    return $serial;
}

sub getMacAddress {
    my ($self) = @_;

    return getCanonicalMacAddress(getCanonicalString($self->get(hwgWldMac) || $self->get(hwgSteMac)  || $self->get(hwgSte2Mac)));
}

sub getModel {
    my ($self) = @_;

    return $self->get(hwgModel);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Hwg - Inventory module for Hwg

=head1 DESCRIPTION

This module enhances Hwg devices support.
