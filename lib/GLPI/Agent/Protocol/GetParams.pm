package GLPI::Agent::Protocol::GetParams;

use strict;
use warnings;

use parent 'GLPI::Agent::Protocol::Message';

use GLPI::Agent::Version;

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(
        supported_params    => [ qw(params_id use deviceid) ],
        %params
    );

    bless $self, $class;

    # Setup request with action for this message if it's not a server answer
    unless ($self->get('status')) {
        my $message = $self->get;
        $message->{action}   = 'get_params';
        $message->{name}     = $GLPI::Agent::Version::PROVIDER . "-Agent";
        $message->{version}  = $GLPI::Agent::Version::VERSION;
    }

    return $self;
}

sub is_valid_message {
    my ($self) = @_;

    return 0 unless defined($self->get);

    my $status = $self->get("status") // "ok";
    return 1 if $status eq "error";

    # Message from server CAN contain:
    #  - a simple 'credentials' array
    return 1 if ref($self->get("credentials")) eq 'ARRAY';

    return 0;
}

1;

__END__

=head1 NAME

GLPI::Agent::Protocol::GetParams - GetParams GLPI Agent messages

=head1 DESCRIPTION

This is a class to handle GetParams protocol messages.

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
