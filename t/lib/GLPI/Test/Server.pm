package GLPI::Test::Server;

use warnings;
use strict;
use parent qw(HTTP::Server::Simple::CGI HTTP::Server::Simple::Authen);

use English qw(-no_match_vars);
use IO::Socket::SSL;
use Socket;

use GLPI::Test::Auth;

my $dispatch_table = {};

=head1 OVERLOADED METHODS

=cut

our $pid;

sub new {
    die 'An instance of Test::Server has already been started.' if $pid;

    my $class = shift;
    my %params = (
        port => 8080,
        ssl  => 0,
        crt  => undef,
        key  => undef,
        @_
    );

    my $self = $class->SUPER::new($params{port});

    $self->{user}     = $params{user};
    $self->{password} = $params{password};
    $self->{ssl}      = $params{ssl};
    $self->{crt}      = $params{crt};
    $self->{key}      = $params{key};

    $self->host('127.0.0.1');

    return $self;
}

sub authen_handler {
    my ($self) = @_;
    return GLPI::Test::Auth->new(
        user     => $self->{user},
        password => $self->{password}
    );
}

sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $path = $cgi->path_info();
    my $handler = $dispatch_table->{$path};

    if ($handler) {
        if (ref($handler) eq "CODE") {
            $handler->($self, $cgi);
        } else {
            print "HTTP/1.0 200 OK\r\n";
            print "\r\n";
            print $handler;
        }
    } else {
        print "HTTP/1.0 404 Not found\r\n";
        print
        $cgi->header(),
        $cgi->start_html('Not found'),
        $cgi->h1('Not found'),
        $cgi->end_html();
    }

    # fix for strange bug under Test::Harness
    # where HTTP::Server::Simple::CGI::Environment::header
    # keep appending value to this variable
    delete $ENV{CONTENT_LENGTH};
}

# overriden to add status to return code in the headers
sub authenticate {
    my $self = shift;
    my $user = $self->do_authenticate();
    unless (defined $user) {
        my $realm = $self->authen_realm();
        print "HTTP/1.0 401 Authentication required\r\n";
        print qq(WWW-Authenticate: Basic realm="$realm"\r\n\r\n);
        print "Authentication required.";
        return;
    }
    return $user;
}

sub print_banner {
}

sub accept_hook {
    my $self = shift;

    return unless $self->{ssl};
    my $fh   = $self->stdio_handle;

    $self->SUPER::accept_hook(@_);

    my $newfh = IO::Socket::SSL->start_SSL($fh,
        SSL_server    => 1,
        SSL_use_cert  => 1,
        SSL_cert_file => $self->{crt},
        SSL_key_file  => $self->{key},
    );

    $self->stdio_handle($newfh) if $newfh;
}

=head1 METHODS UNIQUE TO TestServer

=cut

sub set_dispatch {
    my $self = shift;
    $dispatch_table = shift;

    return;
}

sub background {
    my $self = shift;

    $pid = $self->SUPER::background()
        or Carp::confess( q{Can't start the test server} );

    sleep 1; # background() may come back prematurely, so give it a second to fire up

    return $pid;
}

# Use updated _process_request() to avoid error on undefined $remote_sockaddr
sub _process_request {
    my $self = shift;

    # Create a callback closure that is invoked for each incoming request;
    # the $self above is bound into the closure.
    sub {

        $self->stdio_handle(*STDIN) unless $self->stdio_handle;

 # Default to unencoded, raw data out.
 # if you're sending utf8 and latin1 data mixed, you may need to override this
        binmode STDIN,  ':raw';
        binmode STDOUT, ':raw';

        # The ternary operator below is to protect against a crash caused by IE
        # Ported from Catalyst::Engine::HTTP (Originally by Jasper Krogh and Peter Edwards)
        # ( http://dev.catalyst.perl.org/changeset/5195, 5221 )

        my $remote_sockaddr = getpeername( $self->stdio_handle );
        my $family = $remote_sockaddr ? sockaddr_family($remote_sockaddr) : AF_INET;

        my ( $iport, $iaddr ) = $remote_sockaddr
                                ? ( ($family == AF_INET6) ? sockaddr_in6($remote_sockaddr)
                                                          : sockaddr_in($remote_sockaddr) )
                                : (undef,undef);

        my $loopback = ($family == AF_INET6) ? "::1" : "127.0.0.1";
        my $peeraddr = $loopback;
        if ($iaddr) {
            my ($host_err,$addr, undef) = Socket::getnameinfo($remote_sockaddr,Socket::NI_NUMERICHOST);
            warn ($host_err) if $host_err;
            $peeraddr = $addr || $loopback;
        }

        my ( $method, $request_uri, $proto ) = $self->parse_request;

        unless ($self->valid_http_method($method) ) {
            $self->bad_request;
            return;
        }

        $proto ||= "HTTP/0.9";

        my ( $file, $query_string )
            = ( $request_uri =~ /([^?]*)(?:\?(.*))?/s );    # split at ?

        $self->setup(
            method       => $method,
            protocol     => $proto,
            query_string => ( defined($query_string) ? $query_string : '' ),
            request_uri  => $request_uri,
            path         => $file,
            localname    => $self->host,
            localport    => $self->port,
            peername     => $peeraddr,
            peeraddr     => $peeraddr,
            peerport     => $iport,
        );

        # HTTP/0.9 didn't have any headers (I think)
        if ( $proto =~ m{HTTP/(\d(\.\d)?)$} and $1 >= 1 ) {
            my $headers = $self->parse_headers
                or do { $self->bad_request; return };

            $self->headers($headers);
        }

        $self->post_setup_hook if $self->can("post_setup_hook");

        $self->handler;
    }
}

sub root {
    my $self = shift;
    my $port = $self->port;
    my $hostname = $self->host;

    return "http://$hostname:$port";
}

sub stop {
    my $signal = ($OSNAME eq 'MSWin32') ? 9 : 15;
    if ($pid) {
        kill($signal, $pid) unless $EXCEPTIONS_BEING_CAUGHT;
        waitpid($pid, 0);
        undef $pid;
    }

    return;
}

1;
