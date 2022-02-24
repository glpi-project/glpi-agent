package GLPI::Agent::SNMP;

use strict;
use warnings;

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

our $VERSION = '1.1';

sub get_first {
    my ($self, $oid) = @_;

    my $values = $self->walk($oid);
    return unless $values;

    my $value =
        first { $_ }
        map   { $values->{$_} }
        sort  { $a <=> $b }
        keys %$values;

    return $value;
}

1;
__END__

=head1 NAME

GLPI::Agent::SNMP - Base class for SNMP client

=head1 DESCRIPTION

This is the object used by the agent to perform SNMP queries.

=head1 METHODS

=head2 switch_vlan_context($vlan_id)

Switch to a new vlan-specific context.

With SNMPv1 and SNMPv2, this creates a new SNMP connection, using a community
derived from original one, with vlan ID appended as a suffix. With SNMPv3,
ensure all subsequent requests use relevant context.

=head2 reset_original_context()

Reset to original context.

=head2 get($oid)

This method returns the value from the SNMP object with given OID.

=head2 get_first($oid)

This method returns the first first non-null value from the SNMP table with
given OID.

=head2 walk($oid)

This method returns all values from the SNMP table with given OID, indexed by
their index.
