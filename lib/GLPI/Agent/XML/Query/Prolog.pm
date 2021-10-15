package GLPI::Agent::XML::Query::Prolog;

use strict;
use warnings;

use parent 'GLPI::Agent::XML::Query';

sub new {
    my ($class, %params) = @_;

    die "no deviceid parameter for Prolog XML query\n" unless $params{deviceid};

    return $class->SUPER::new(
        query => 'PROLOG',
        token => '12345678',
        %params
    );

}

1;
__END__

=head1 NAME

GLPI::Agent::XML::Query::Prolog - Prolog agent message

=head1 DESCRIPTION

This is an initial message sent by the agent to the server before any task is
processed, requiring execution parameters.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, in addition to those
from the base class C<GLPI::Agent::XML::Query>, as keys of the
%params hash:

=over

=back
