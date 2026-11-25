package GLPI::Agent::HTTP::Kerberos;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;
use MIME::Base64;
use Digest::SHA;

# Kerberos support for HTTP Negotiate authentication (RFC 4559) based on
# GSSAPI perl module, a binding of the GSSAPI C library (RFC 2743/2744)
# provided by MIT Kerberos or Heimdal.
#
# HTTP Negotiate authentication with Kerberos works this way:
#  1. the client sends its request without authentication,
#  2. the server answers "401" with a "WWW-Authenticate: Negotiate" header,
#  3. the client asks its Kerberos library for a token targeting the
#     HTTP/<server-fqdn> service principal. To compute it, the library looks
#     for a Ticket Granting Ticket (TGT) in the credentials cache (KRB5CCNAME,
#     filled by "kinit") or gets one by itself from a client keytab
#     (KRB5_CLIENT_KTNAME with MIT Kerberos). It then requests a service
#     ticket for HTTP/<server-fqdn> to the KDC (the domain controller in an
#     Active Directory domain) and stores it in the credentials cache next
#     to the TGT, so the KDC is only asked once while the ticket is valid.
#     The token itself is never stored: it is a Kerberos AP-REQ message
#     built on each call from the service ticket and a new authenticator
#     encrypted with the session key of that ticket,
#  4. the client replays its request with "Authorization: Negotiate <token>",
#  5. the server decrypts the token with its own key and, on success, answers
#     the request with a "WWW-Authenticate: Negotiate <token>" header,
#  6. the client verifies that last token (a Kerberos AP-REP message), proving
#     the server knows the service key and so is the expected server. This is
#     the mutual authentication.
#
# Over https, the token of step 3 can also be bound to the TLS channel (RFC
# 5929 "tls-server-end-point" channel binding, known as Extended Protection for
# Authentication on Windows): the client adds a hash of the server certificate
# in the token, so a token captured by a man-in-the-middle can't be relayed to
# the real server over another TLS connection. WinRM requires it when its
# CbtHardeningLevel is set to Strict. See channel_binding().
#
# This module handles steps 3 & 6, GLPI::Agent::HTTP::Client handles the HTTP
# part and provides the server certificate for channel binding. No password is ever handled by the agent: it only uses the tickets the
# Kerberos library finds by itself.

sub new {
    my ($class, %params) = @_;

    my $self = {
        _host   => $params{host},
        _error  => '',
    };
    bless $self, $class;

    # GSSAPI is not a mandatory dependency, so load it at runtime.
    # GSSAPI::Status & GSSAPI::OID are loaded by GSSAPI import(), which is not
    # called by require(), so require them explicitly
    unless (GSSAPI->require() && GSSAPI::Status->require() && GSSAPI::OID->require()) {
        $self->{_error} = "GSSAPI perl module is required for kerberos authentication";
        return $self;
    }

    unless ($self->{_host}) {
        $self->{_error} = "no host defined for kerberos authentication";
        return $self;
    }

    # Build the target name, gss_import_name() in C API. "HTTP@host" with the
    # gss_nt_hostbased_service name type is the portable GSSAPI way to name
    # the HTTP/host service principal. The Kerberos library adds the realm
    # following its domain_realm configuration or the KDC referrals. Note that
    # with the MIT Kerberos default configuration (dns_canonicalize_hostname &
    # rdns in krb5.conf), the library may canonicalize the host name with DNS
    # before building the principal, so the requested principal can differ
    # from the one returned by service().
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

# Compute the RFC 5929 "tls-server-end-point" channel binding application data
# from the DER encoded server certificate and its signature algorithm name, as
# returned by OpenSSL like "RSA-SHA256" or "ecdsa-with-SHA384". The certificate
# is hashed with the hash function of its signature algorithm, except MD5 and
# SHA-1 which are replaced by SHA-256 (RFC 5929 section 4.1). SHA-256 is also
# used for signature algorithms without hash function name, like RSASSA-PSS or
# Ed25519.
sub tlsServerEndPoint {
    my ($der, $sigalg) = @_;

    return unless defined($der) && length($der);

    my $algorithm = 256;
    if ($sigalg) {
        if ($sigalg =~ /sha-?512[-\/](224|256)/i) {
            $algorithm = "512$1";
        } elsif ($sigalg =~ /sha-?(224|384|512)/i) {
            $algorithm = $1;
        }
    }

    return "tls-server-end-point:" . Digest::SHA->new($algorithm)->add($der)->digest;
}

# Set channel binding application data to use with following tokens, or reset
# it when called without data
sub channel_binding {
    my ($self, $data) = @_;

    delete $self->{_bindings};

    return unless defined($data) && length($data);

    # gss_channel_bindings_struct in C API. The Kerberos library puts a hash of
    # the whole structure in the token authenticator, so it must be identical
    # to the one computed by the server. Windows SSPI only sets the application
    # data and leaves address types to 0 (GSS_C_AF_UNSPEC), but GSSAPI::Binding
    # initializes them to GSS_C_AF_NULLADDR, so they must be set explicitly.
    my $bindings = GSSAPI::Binding->new();
    $bindings->set_initiator(GSSAPI::GSS_C_AF_UNSPEC(), '');
    $bindings->set_acceptor(GSSAPI::GSS_C_AF_UNSPEC(), '');
    $bindings->set_appl_data($data);

    $self->{_bindings} = $bindings;
}

sub _bindings {
    my ($self) = @_;
    return $self->{_bindings} // GSSAPI::GSS_C_NO_CHANNEL_BINDINGS();
}

# Return the base64 encoded token to submit in "Authorization: Negotiate" header
# or undef on failure. Initialize a new security context on each call.
sub token {
    my ($self) = @_;

    # Target name import failure is definitive
    return unless $self->{_target};
    $self->{_error} = '';

    # gss_init_sec_context() in C API. The first call on a new context returns
    # the token to send to the server. The context keeps the state needed to
    # verify the server answer in verify().
    my $ctx = GSSAPI::Context->new();
    my $otoken;
    my $status = $ctx->init(
        # Credentials: none given, so the library uses the default ones, the
        # TGT from credentials cache or from the client keytab
        GSSAPI::GSS_C_NO_CREDENTIAL(),
        # Target name: HTTP/host service principal
        $self->{_target},
        # Mechanism: Kerberos 5 only. RFC 4559 describes Negotiate with the
        # SPNEGO mechanism, but the Windows Negotiate security package also
        # accepts raw Kerberos 5 tokens, which keeps the exchange to a single
        # round-trip. The test suite uses an MIT Kerberos acceptor, so this
        # Windows behavior is not covered by tests.
        GSSAPI::OID::gss_mech_krb5(),
        # Flags: request mutual authentication so the server returns a token
        # proving its identity
        GSSAPI::GSS_C_MUTUAL_FLAG(),
        # Requested context lifetime: 0 means the library default
        0,
        # Channel bindings: the ones set by channel_binding() over https or
        # none. Windows hosts with WinRM CbtHardeningLevel set to Strict refuse
        # a token without channel binding, the default Relaxed level only
        # refuses a token with a wrong one.
        $self->_bindings(),
        # Input token: none as this is the first call
        '',
        # Output values: actual mechanism, token to send, flags and lifetime.
        # Only the token is needed.
        undef,
        $otoken,
        undef,
        undef,
    );

    # GSS_S_CONTINUE_NEEDED: the token is ready and the server answer must be
    # passed back to init() to complete the context, this is what is expected
    # as mutual authentication is requested, see verify()
    if ($status->major == GSSAPI::GSS_S_CONTINUE_NEEDED()) {
        $self->{_ctx} = $ctx;
        return encode_base64($otoken // '', '');
    }

    # GSS_S_COMPLETE: the token is ready and no more exchange is possible, so
    # the server identity could not be verified. This is not expected with
    # Kerberos 5 mechanism when mutual authentication is requested.
    if ($status->major == GSSAPI::GSS_S_COMPLETE()) {
        delete $self->{_ctx};
        $self->{_error} = "kerberos mutual authentication not supported for ".$self->service();
        return;
    }

    # Typical failures are no ticket in credentials cache, expired ticket,
    # KDC not reachable or unknown service principal
    delete $self->{_ctx};
    $self->{_error} = "failed to get kerberos token for ".$self->service().": "._status($status);

    return;
}

# Verify mutual authentication token returned by the server
sub verify {
    my ($self, $token) = @_;

    # A token can only be verified by the context which produced the request
    # token, and only once
    my $ctx = delete $self->{_ctx};
    unless ($ctx) {
        $self->{_error} = "kerberos mutual authentication failed for ".$self->service().": no pending authentication";
        return 0;
    }

    unless (defined($token) && length($token)) {
        $self->{_error} = "kerberos mutual authentication failed for ".$self->service().": no token provided by server";
        return 0;
    }

    # Second gss_init_sec_context() call on the same context with the server
    # token as input. Parameters must be the same as in token(). The library
    # checks the token was encrypted with the session key shared with the
    # server through the service ticket.
    my ($otoken, $oflags);
    my $status = $ctx->init(
        GSSAPI::GSS_C_NO_CREDENTIAL(),
        $self->{_target},
        GSSAPI::OID::gss_mech_krb5(),
        GSSAPI::GSS_C_MUTUAL_FLAG(),
        0,
        $self->_bindings(),
        decode_base64($token),
        undef,
        $otoken,
        $oflags,
        undef,
    );

    # GSS_S_COMPLETE with the mutual flag in returned flags means the server
    # identity is verified
    if ($status->major == GSSAPI::GSS_S_COMPLETE()) {
        return 1 if $oflags && ($oflags & GSSAPI::GSS_C_MUTUAL_FLAG());
        $self->{_error} = "kerberos mutual authentication failed for ".$self->service().": not provided by security context";
        return 0;
    }

    $self->{_error} = "kerberos mutual authentication failed for ".$self->service().": "._status($status);

    return 0;
}

# Format a GSSAPI::Status as an error message
sub _status {
    my ($status) = @_;

    # Should always be a GSSAPI::Status object, which is false in boolean
    # context on error through overloading
    return "unknown error" unless ref($status);

    # Major status code message comes from GSSAPI, like "No credentials were supplied"
    my @messages = grep { defined($_) && length($_) } $status->generic_message();
    # Minor status code message comes from Kerberos library, like "Server not
    # found in Kerberos database", it is only relevant with a minor status code
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
authentication (RFC 4559) and verifies the server token for mutual
authentication. It relies on the GSSAPI perl module.

No password is handled: a Kerberos ticket must be available from the
credentials cache (see C<kinit> and C<KRB5CCNAME>) or the Kerberos library
must be able to get one from a client keytab (see C<KRB5_CLIENT_KTNAME> with
MIT Kerberos).

See t/agent/http/kerberos.t for a complete usage example against a test realm
set up by t/lib/GLPI/Test/Kerberos.pm.

=head1 METHODS

=head2 new(%params)

The constructor. The C<host> parameter is mandatory and should be the fully
qualified domain name of the server as the C<HTTP/host> service principal is
used.

=head2 tlsServerEndPoint($der, $sigalg)

Function computing the RFC 5929 C<tls-server-end-point> channel binding data
from the DER encoded server certificate and the name of its signature
algorithm. Return undef without certificate.

=head2 channel_binding($data)

Set channel binding application data to be used with following tokens, as
computed by tlsServerEndPoint(). This is required by WinRM over https when
CbtHardeningLevel is set to Strict. Call it without data to not use channel
binding.

=head2 token()

Return the base64 encoded Kerberos token or undef on error. Each call starts
a new authentication.

=head2 verify($token)

Verify the base64 encoded token returned by the server for mutual
authentication. Must be called after token() and can only be called once.

=head2 error()

Return the last error.

=head2 service()

Return the targeted service principal name, like C<HTTP/host>.
