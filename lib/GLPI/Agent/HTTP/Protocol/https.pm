package GLPI::Agent::HTTP::Protocol::https;

use strict;
use warnings;
use parent qw(LWP::Protocol::https);

use IO::Socket::SSL qw(SSL_VERIFY_NONE SSL_VERIFY_PEER);

sub import {
    my ($class, %params) = @_;

    # set default context
    IO::Socket::SSL::set_ctx_defaults(ca_file => $params{ca_cert_file})
        if $params{ca_cert_file};
    IO::Socket::SSL::set_ctx_defaults(ca_path => $params{ca_cert_dir})
        if $params{ca_cert_dir};
    IO::Socket::SSL::set_ctx_defaults(ssl_cert_file => $params{ssl_cert_file})
        if $params{ssl_cert_file};
    IO::Socket::SSL::set_ctx_defaults(ssl_ca => $params{ssl_ca})
        if $params{ssl_ca};
    IO::Socket::SSL::set_ctx_defaults(ssl_fingerprint => $params{ssl_fingerprint})
        if $params{ssl_fingerprint} && $IO::Socket::SSL::VERSION >= 1.967;
}

sub _extra_sock_opts {
    my ($self, $host) = @_;

    return (
        SSL_verify_mode     => $self->{ua}->{ssl_check} ?
                                SSL_VERIFY_PEER : SSL_VERIFY_NONE,
        SSL_verifycn_scheme => 'http',
        SSL_verifycn_name   => $host
    );
}

## no critic (ProhibitMultiplePackages)
package GLPI::Agent::HTTP::Protocol::https::Socket;

use parent qw(Net::HTTPS);
use parent -norequire, qw(LWP::Protocol::http::SocketMethods);

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Protocol::https - HTTPS protocol handler for LWP

=head1 DESCRIPTION

This is an overrided HTTPS protocol handler for LWP, allowing to use
subjectAltNames for checking server certificate.
