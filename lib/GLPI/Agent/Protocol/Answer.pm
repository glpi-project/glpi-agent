package GLPI::Agent::Protocol::Answer;

use strict;
use warnings;

use parent 'GLPI::Agent::Protocol::Message';

use Cpanel::JSON::XS;

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(
        %params,
        supported_params    => [ qw(status expiration) ],
    );

    bless $self, $class;

    $self->{_http_code}   = $params{httpcode}   // 200;
    $self->{_http_status} = $params{httpstatus} // "OK";
    $self->{_agentid}     = $params{agentid}    // "";
    $self->{_proxyids}    = $params{proxyids}   // "";

    # Handle case message was a dump
    foreach my $key (qw(_http_code _http_status _agentid _proxyids)) {
        my $value = $self->delete($key);
        $self->{$key} = $value if $value;
    }

    return $self;
}

sub error {
    my ($self, $error) = @_;

    return unless defined($error);

    $self->{_message}->{status} = 'error';
    $self->{_message}->{message} = $error;
    delete $self->{_messages}->{expiration};

    # Returning an error message is still a good HTTP message
    $self->{_http_code}   = 200;
    $self->{_http_status} = "OK";
}

sub contentType {
    return "application/json";
}

sub http_code {
    my ($self) = @_;
    return $self->{_http_code};
}

sub http_status {
    my ($self) = @_;
    return $self->{_http_status};
}

sub agentid {
    my ($self) = @_;
    return $self->{_agentid};
}

sub proxyid {
    my ($self) = @_;
    return $self->{_proxyids};
}

sub dump {
    my ($self) = @_;

    my %dump = map { $_ => $self->{_message}->{$_} } keys(%{$self->{_message}});
    map { $dump{$_} = $self->{$_} } qw(_http_code _http_status _agentid _proxyids);

    return encode_json(\%dump);
}

sub success {
    my ($self) = @_;

    $self->{_http_code}   = 200;
    $self->{_http_status} = "OK";
    $self->{_message}->{status} = "ok" if $self->status eq "pending";
}

1;

__END__

=head1 NAME

GLPI::Agent::Protocol::Answer - Answer for GLPI Agent messages

=head1 DESCRIPTION

This is a class to handle answer protocol messages.

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

=head2 error($error)

Update the message with a status error
