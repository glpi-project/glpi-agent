package GLPI::Test::Proxy;

use strict;
use warnings;

use English qw(-no_match_vars);
use HTTP::Proxy;
use File::Temp;

our $pid;

sub new {
    die 'An instance of Test::Proxy has already been started.' if $pid;

    my $class = shift;

    my $proxy = HTTP::Proxy->new(port => 0);
    $proxy->init();
    $proxy->agent()->no_proxy('localhost');
    $proxy->logfh(File::Temp->new());

    # keep behaviour consistant with previous LWP version
    if ($LWP::VERSION >= 6) {
        $proxy->agent()->ssl_opts(verify_hostname => 0);
    }

    my $self = {
        proxy => $proxy
    };
    bless $self, $class;

    return $self;
}

# the proxy accepts an optional coderef to run after serving all requests
sub background {
    my ($self, $sub) = @_;

    $pid = fork;
    die "Unable to fork proxy" if not defined $pid;

    if ($pid == 0) {
        $0 .= " (proxy)";

        # this is the http proxy
        $self->{proxy}->start();
        $sub->($self->{proxy}) if ( defined $sub and ref $sub eq 'CODE' );
        exit 0;
    }

    # back to the parent
    return $pid;
}

sub url {
    my ($self) = @_;

    return $self->{proxy}->url();
}

sub stop {
    my $signal = ($OSNAME eq 'MSWin32') ? 9 : 15;
    if ($pid) {
        kill($signal, $pid) unless $EXCEPTIONS_BEING_CAUGHT;
        undef $pid;
    }

    return;
}

1;
