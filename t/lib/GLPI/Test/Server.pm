package FusionInventory::Test::Server;

use warnings;
use strict;
use parent qw(HTTP::Server::Simple::CGI HTTP::Server::Simple::Authen);

use English qw(-no_match_vars);
use IO::Socket::SSL;

use FusionInventory::Test::Auth;

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

# Fixed and very simplified run method refactored from HTTP::Server::Simple run & _default_run methods
sub run {
    my $self = shift;

    local $SIG{CHLD} = 'IGNORE';    # reap child processes

    $self->setup_listener;
    $self->after_setup_listener();

    local $SIG{PIPE} = 'IGNORE'; # If we don't ignore SIGPIPE, a
                                 # client closing the connection before we
                                 # finish sending will cause the server to exit

    while ( accept( my $remote = new FileHandle, HTTP::Server::Simple::HTTPDaemon ) ) {
        $self->stdio_handle($remote);

        # This is the point, we must not continue processing the request if SSL failed !!!
        if ($self->accept_hook || !$self->{ssl}) {
            *STDIN  = $self->stdin_handle();
            *STDOUT = $self->stdout_handle();
            select STDOUT;
            &{$self->_process_request};
        }
        close $self->stdio_handle;
    }
}

sub authen_handler {
    my ($self) = @_;
    return FusionInventory::Test::Auth->new(
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
