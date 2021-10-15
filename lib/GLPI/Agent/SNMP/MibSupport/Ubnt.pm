package GLPI::Agent::SNMP::MibSupport::Ubnt;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See UBNT-MIB

use constant ubnt               => '.1.3.6.1.4.1.41112';
use constant ubntWlStatApMac    => ubnt . '.1.4.5.1.4.1';

our $mibSupport = [
    {
        name    => "ubnt",
        oid     => ubnt
    }
];

sub getSerial {
    my ($self) = @_;

    my $serial = getCanonicalMacAddress($self->get(ubntWlStatApMac));
    $serial =~ s/://g;

    return $serial;
}

sub getMacAddress {
    my ($self) = @_;

    return $self->get(ubntWlStatApMac);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Ubnt - Inventory module for Ubnt

=head1 DESCRIPTION

This module enhances Ubnt devices support.
