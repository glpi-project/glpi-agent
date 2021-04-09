package GLPI::Agent::Protocol::Message;

use strict;
use warnings;

use JSON;

use FusionInventory::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger      => $params{logger} // FusionInventory::Agent::Logger->new(),
        _message    => $params{message} // {},
    };

    bless $self, $class;

    # Parse message if not given as a ref
    $self->set($params{message}) unless ref($params{message});

    # Load supported params if not a server response
    unless ($self->get('status') || !$params{supported_params}) {
        my $message = $self->get;
        foreach my $param (@{$params{supported_params}}) {
            $message->{$param} = $params{$param} if defined($params{$param});
        }
    }

    return $self;
}

sub _convert {
    my ($hash) = @_;

    return unless ref($hash) eq 'HASH';

    foreach my $key (keys(%{$hash})) {
        my $value = $hash->{$key};
        map { _convert($_) } ref($value) eq 'ARRAY' ? @{$value} : $value;
        next if lc($key) eq $key;
        $hash->{lc($key)} = delete $hash->{$key};
    }

    return $hash;
}

sub getContent {
    my ($self) = @_;

    return $self->{_message} unless ref($self->{_message});

    return encode_json(_convert($self->{_message}));
}

sub print {
    my ($self) = @_;

    return $self->{_message} unless ref($self->{_message});

    return JSON->new->utf8->pretty->encode(_convert($self->{_message}));
}

sub set {
    my ($self, $message) = @_;

    return unless defined($message);

    return $self->{_message} = decode_json($message);
}

sub get {
    my ($self, $what) = @_;

    return $self->{_message}->{$what} if defined($what) && defined($self->{_message});

    return $self->{_message};
}

sub delete {
    my ($self, $what) = @_;

    return unless defined($what) && defined($self->{_message});

    return delete $self->{_message}->{$what};
}

sub expiration {
    my ($self) = @_;

    return 0 unless defined($self->{_message}) && defined($self->{_message}->{expiration});

    return 0 unless $self->{_message}->{expiration} =~ /^(\d+)([dshm]?)$/;

    return
        !$2       ? int($1)*3600    :
        $2 eq 's' ? int($1)         :
        $2 eq 'm' ? int($1)*60      :
        $2 eq 'h' ? int($1)*3600    :
                    int($1)*86400   ;
}

sub action {
    my ($self) = @_;

    return $self->get('action');
}

sub status {
    my ($self) = @_;

    return $self->get('status');
}

sub is_valid_message {
    my ($self) = @_;

    return defined($self->get) && $self->status ? 1 : 0;
}

1;

__END__

=head1 NAME

GLPI::Agent::Protocol::Message - Base class for GLPI Agent messages

=head1 DESCRIPTION

This is an abstract class for all JSON messages sent and received by the agent to
or from a server or a proxy agent.

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

=head2 getContent

Get decoded JSON content as a hash.

=head2 set($message)

Set the message from a JSON string

=head2 get($what)

Get the message as a perl structure or the $what part only
