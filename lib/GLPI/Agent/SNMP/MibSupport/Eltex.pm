package GLPI::Agent::SNMP::MibSupport::Eltex;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# ELTEX-MIB enterprise root
use constant    eltex   => '.1.3.6.1.4.1.35265';

our $mibSupport = [
    {
        name        => "eltex",
        sysobjectid => getRegexpOidMatch(eltex)
    }
];

sub getManufacturer {
    return "Eltex";
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $ports = $device->{PORTS}->{PORT}
        or return;

    # Eltex firmwares expose dot3StatsDuplexStatus (IFPORTDUPLEX) entries for
    # interface indexes that don't exist in ifTable. As network ports are built
    # from a sparse hash indexed by interface identifier, these extra entries
    # create phantom ports carrying nothing but a duplex value. A real interface
    # always has an ifIndex (IFNUMBER), so drop entries that don't have one.
    foreach my $index (keys %{$ports}) {
        delete $ports->{$index}
            unless defined $ports->{$index}->{IFNUMBER};
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Eltex - Inventory module for Eltex devices

=head1 DESCRIPTION

The module enhances Eltex devices support.

It removes phantom network ports reported by some Eltex firmwares which expose
duplex status entries for non-existent interfaces.
