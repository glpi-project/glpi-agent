package GLPI::Agent::XML::Query;

use strict;
use warnings;

use GLPI::Agent::XML;

sub new {
    my ($class, %params) = @_;

    die "no query parameter for XML query\n" unless $params{query};

    my $self = {};
    bless $self, $class;

    foreach my $key (keys %params) {
        $self->{h}->{uc($key)} = $params{$key};
    }
    return $self;
}

sub getContent {
    my ($self) = @_;

    return GLPI::Agent::XML->new()->write({ REQUEST => $self->{h} });
}


1;

__END__

=head1 NAME

GLPI::Agent::XML::Query - Base class for agent messages

=head1 DESCRIPTION

This is an abstract class for all XML query messages sent by the agent to the
server.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use

=item I<deviceid>

the agent identifier (optional)

=back

=head2 getContent

Get XML content.
