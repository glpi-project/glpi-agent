package GLPI::Agent::HTTP::Server::SSL;

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Spec;

use base "GLPI::Agent::HTTP::Server::Plugin";

use GLPI::Agent::Tools;

our $VERSION = "1.1";

sub log_prefix {
    return "[ssl server plugin] ";
}

sub config_file {
    return "ssl-server-plugin.cfg";
}

sub defaults {
    return {
        disabled            => "yes",
        ports               => 0,
        # SSL support
        ssl_cert_file       => undef,
        ssl_key_file        => undef,
        ssl_cipher          => undef,
    };
}

sub init {
    my ($self) = @_;

    $self->SUPER::init(@_);

    # Don't verify SSL configuration if disabled
    return if $self->disabled();

    # Get absolute canonical path
    $self->{'cert_file'} = File::Spec->rel2abs($self->config('ssl_cert_file'),$self->confdir())
        if $self->config('ssl_cert_file');
    $self->{'key_file'} = File::Spec->rel2abs($self->config('ssl_key_file'),$self->confdir())
        if $self->config('ssl_key_file');
    $self->{'cipher'} = $self->config('ssl_cipher')
        if $self->config('ssl_cipher');

    # Check certificate file is set
    unless ($self->{'cert_file'}) {
        $self->error("Plugin enabled without certificate file set in configuration");
        $self->disable("Plugin disabled on wrong configuration");
        return;
    }

    # Check certificate file exists
    unless (-e $self->{'cert_file'}) {
        $self->error("Plugin enabled but $self->{'cert_file'} certificate file is missing");
        $self->disable("Plugin disabled on wrong configuration");
        return;
    }

    # Check key file exists if set
    if ($self->{'key_file'} && ! -e $self->{'key_file'}) {
        $self->error("Plugin enabled but $self->{'key_file'} key file is missing");
        $self->disable("Plugin disabled on wrong configuration");
        return;
    }

    # If key file is missing assume it is included in cert file
    $self->{'key_file'} = $self->{'cert_file'}
        unless $self->{'key_file'};

    # Setup ports as an array ref
    $self->{ports} = [ grep { defined && $_ < 65536 } split(/,/, $self->config('ports') || 0) ];

    # Load IO::Socket::SSL module
    IO::Socket::SSL->require();
    if ($EVAL_ERROR) {
        $self->error("HTTPD can't load SSL support: $EVAL_ERROR");
        $self->disable("Plugin disabled on wrong configuration");
        return;
    }

    $self->debug2("Certificate file: $self->{'cert_file'}");
    $self->debug2("Key file:         $self->{'key_file'}");
    $self->debug2("Cipher:           ".($self->{cipher}//"n/a"));

    # Activate SSL Debug if Stderr is in backends
    my $DEBUG_SSL = 0;
    $DEBUG_SSL = grep { ref($_) =~/Stderr$/ } @{$self->{logger}{backends}}
        if (ref($self->{logger}{backends}) eq 'ARRAY');
    $IO::Socket::SSL::DEBUG = 2
        if ( $DEBUG_SSL && $self->{logger}->debug_level() >= 2 );
}

sub upgrade_SSL {
    my ($self, $client) = @_;

    # try to upgrade socket to SSL
    return HTTP::Daemon::ClientConn::SSL->new(
        client  => $client,
        plugin  => $self,
    );
}

# We use a dedicated package to derivate from IO::Socket::SSL and HTTP::Daemon::ClientConn
# We put the package name on a new line to avoid CPAN indexing
## no critic (ProhibitMultiplePackages,ProhibitExplicitISA)
package
    HTTP::Daemon::ClientConn::SSL;

use vars qw(@ISA);
use English qw(-no_match_vars);

@ISA = qw(IO::Socket::SSL HTTP::Daemon::ClientConn);

sub new {
    my ($class, %params) = @_;

    my $client = $params{client}
        or return;

    my $plugin = $params{plugin}
        or return;

    eval {
        # SSL upgrade client
        IO::Socket::SSL->start_SSL($client,
            SSL_version     => $plugin->{cipher} // "",
            SSL_server      => 1,
            SSL_cert_file   => $plugin->{cert_file},
            SSL_key_file    => $plugin->{key_file},
        ) or die "Failed to upgrade socket to SSL: $IO::Socket::SSL::SSL_ERROR\n";
    };
    if ($EVAL_ERROR) {
        $plugin->debug("HTTPD can't start SSL session: $EVAL_ERROR");
        $client->close();
        return;
    }

    # Disable Timeout to leave SSL session opened until we get data
    $client->timeout(0);

    $plugin->debug("HTTPD started new SSL session");

    bless $client, $class;
}

sub close {
    my ($self) = @_;

    # Don't shutdown SSL on close to avoid issue with Proxy server plugin as it uses forking
    $self->SUPER::close(SSL_no_shutdown => 1);
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Server::SSL - An embedded HTTP server plugin
providing SSL support on configured port

=head1 DESCRIPTION

This is a server plugin to enable SSL support on listening ports.

=head1 CONFIGURATION

=over

=item disabled         C<yes> by default

=item ports            C<0> by default to use default one
                       Can be a comma separated list of ports, even including 0
                       to enable it on default port:
                           Example: ports = 443,0

=item ssl_cert_file    No default
                       The path to SSL certificate to use. It can be relative to
                       the current configuration folder.

=item ssl_key_file     No default
                       The path to SSL private key to use. It can be relative to
                       the current configuration folder.

=item ssl_cipher       No default
                       The cipher or SSL version to use or a list of cipher to
                       disable. GLPI agent use the system default if not set.

=back

Defaults can be overrided in C<ssl-server-plugin.cfg> file or better in the
C<ssl-server-plugin.local> if included from C<ssl-server-plugin.cfg>.

OpenSSL can be used to generate private key/certificate files pair. The following
command can be used:
    openssl req -x509 -newkey rsa:2048 -keyout etc/key.pem -out etc/cert.pem \
        -days 3650 -sha256 -nodes -subj "/CN=$HOSTNAME"
