package GLPI::Agent::XML::Query::Inventory;

use strict;
use warnings;

use parent 'GLPI::Agent::XML::Query';

sub new {
    my ($class, %params) = @_;

    die "no content parameter for XML query\n" unless $params{content};

    return $class->SUPER::new(
        query => 'INVENTORY',
        %params
    );
}

1;
__END__

=head1 NAME

GLPI::Agent::XML::Query::Inventory - Inventory agent message

=head1 DESCRIPTION

This is an inventory message sent by the agent to the server, using OCS
Inventory XML format.

The data strcture format is documented in L<GLPI::Agent::Inventory>.


=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, in addition to those
from the base class C<GLPI::Agent::XML::Query>, as keys of the
%params hash:

=over

=item I<content>

the inventory content (mandatory)

=back
