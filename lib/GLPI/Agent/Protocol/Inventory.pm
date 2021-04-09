package GLPI::Agent::Protocol::Inventory;

use strict;
use warnings;

use parent 'GLPI::Agent::Protocol::Message';

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(
        %params,
        supported_params    => [ qw(deviceid action) ],
        action              => "inventory",
    );

    bless $self, $class;

    return $self;
}

1;

__END__

=head1 NAME

GLPI::Agent::Protocol::Inventory - Inventory GLPI Agent messages

=head1 DESCRIPTION

This is a class to handle Inventory protocol messages.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use

=item I<message>

the message to encode

=back
