package GLPI::Agent::HTTP::Kerberos;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;
use MIME::Base64;

# Kerberos support for HTTP Negotiate authentication (RFC 4559) based on
# GSSAPI perl module. Credentials are taken from the current Kerberos
# credentials cache (see KRB5CCNAME) or from a client keytab when supported
# by the Kerberos library (see KRB5_CLIENT_KTNAME with MIT Kerberos).

sub new {
    my ($class, %params) = @_;

    my $self = {
        _host   => $params{host},
        _error  => '',
    };
    bless $self, $class;

    # GSSAPI::Status & GSSAPI::OID are only loaded by GSSAPI import, so require them explicitly
    unless (GSSAPI->require() && GSSAPI::Status->require() && GSSAPI::OID->require()) {
        $self->{_error} = "GSSAPI perl module is required for kerberos authentication";
        return $self;
    }

    unless ($self->{_host}) {
        $self->{_error} = "no host defined for kerberos authentication";
        return $self;
    }

    my $target;
    my $status = GSSAPI::Name->import(
        $target,
        "HTTP\@".$self->{_host},
        GSSAPI::OID::gss_nt_hostbased_service()
    );
    unless ($status) {
        $self->{_error} = "failed to import kerberos target name: "._status($status);
        return $self;
    }
    $self->{_target} = $target;

    return $self;
}

sub error {
    my ($self) = @_;
    return $self->{_error};
}

sub service {
    my ($self) = @_;
    return "HTTP/".$self->{_host};
}

# Return the base64 encoded token to submit in "Authorization: Negotiate" header
# or undef on failure. Initialize a new security context on each call.
sub token {
    my ($self) = @_;

    return if $self->{_error};

    my $ctx = GSSAPI::Context->new();
    my $otoken;
    my $status = $ctx->init(
        GSSAPI::GSS_C_NO_CREDENTIAL(),
        $self->{_target},
        GSSAPI::OID::gss_mech_krb5(),
        GSSAPI::GSS_C_MUTUAL_FLAG(),
        0,
        GSSAPI::GSS_C_NO_CHANNEL_BINDINGS(),
        '',
        undef,
        $otoken,
        undef,
        undef,
    );

    if ($status->major == GSSAPI::GSS_S_COMPLETE() || $status->major == GSSAPI::GSS_S_CONTINUE_NEEDED()) {
        $self->{_ctx} = $ctx;
        return encode_base64($otoken // '', '');
    }

    delete $self->{_ctx};
    $self->{_error} = "failed to get kerberos token for ".$self->service().": "._status($status);

    return;
}

# Verify mutual authentication token returned by the server
sub verify {
    my ($self, $token) = @_;

    my $ctx = delete $self->{_ctx}
        or return 0;

    return 0 unless defined($token) && length($token);

    my $otoken;
    my $status = $ctx->init(
        GSSAPI::GSS_C_NO_CREDENTIAL(),
        $self->{_target},
        GSSAPI::OID::gss_mech_krb5(),
        GSSAPI::GSS_C_MUTUAL_FLAG(),
        0,
        GSSAPI::GSS_C_NO_CHANNEL_BINDINGS(),
        decode_base64($token),
        undef,
        $otoken,
        undef,
        undef,
    );

    return 1 if $status->major == GSSAPI::GSS_S_COMPLETE();

    $self->{_error} = "kerberos mutual authentication failed for ".$self->service().": "._status($status);

    return 0;
}

sub _status {
    my ($status) = @_;

    # GSSAPI::Status object is false in boolean context on error
    return "unknown error" unless ref($status);

    my @messages = grep { defined($_) && length($_) } $status->generic_message();
    # Mechanism specific message is only relevant with a minor status code
    push @messages, grep { defined($_) && length($_) && $_ ne "Success" } $status->specific_message()
        if $status->minor();

    return @messages ? join(", ", @messages) : "unknown error";
}

1;

__END__

=head1 NAME

GLPI::Agent::HTTP::Kerberos - Kerberos token provider for HTTP Negotiate authentication

=head1 DESCRIPTION

This module computes Kerberos tokens to be used with HTTP Negotiate
authentication. It relies on the GSSAPI perl module and on an existing
Kerberos credentials cache or client keytab.

=head1 METHODS

=head2 new(%params)

The constructor. The C<host> parameter is mandatory and should be the fully
qualified domain name of the server as the C<HTTP/host> service principal is
used.

=head2 token()

Return the base64 encoded Kerberos token or undef on error.

=head2 verify($token)

Verify the base64 encoded token returned by the server for mutual
authentication.

=head2 error()

Return the last error.
