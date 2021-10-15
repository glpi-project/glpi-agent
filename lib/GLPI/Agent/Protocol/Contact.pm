package GLPI::Agent::Protocol::Contact;

use strict;
use warnings;

use parent 'GLPI::Agent::Protocol::Message';

use GLPI::Agent::Version;

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(
        supported_params    => [ qw(deviceid installed-tasks enabled-tasks httpd-plugins httpd-port tag tasks) ],
        %params
    );

    bless $self, $class;

    # Setup request with action for this message if it's not a server answer
    unless ($self->get('status')) {
        my $message = $self->get;
        $message->{action}   = 'contact';
        $message->{name}     = $GLPI::Agent::Version::PROVIDER . "-Agent";
        $message->{version}  = $GLPI::Agent::Version::VERSION;
    }

    return $self;
}

sub is_valid_message {
    my ($self) = @_;

    # CONTACT message from server MUST contain:
    #  - a status
    #  - a valid expiration greater than 0

    return 0 unless $self->SUPER::is_valid_message();
    return $self->expiration > 0  ? 1 : 0;
}

1;

__END__

=head1 NAME

GLPI::Agent::Protocol::Contact - Contact GLPI Agent messages

=head1 DESCRIPTION

This is a class to handle Contact protocol messages.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<message>

the message to encode

=back

=head2 getContent

Get decoded JSON content as a hash.

=head2 set($message)

Set the message from a JSON string

=head2 get()

Get the message as a perl structure
