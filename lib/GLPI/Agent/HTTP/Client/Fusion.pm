package GLPI::Agent::HTTP::Client::Fusion;

use strict;
use warnings;
use parent 'GLPI::Agent::HTTP::Client';

use English qw(-no_match_vars);

use JSON::PP;
use HTTP::Request;
use HTTP::Headers;
use HTTP::Cookies;
use URI::Escape;

use GLPI::Agent::Tools;

use constant    _log_prefix => "[http client] ";

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(
        no_compress => 1,
        %params
    );

    $self->{_cookies} = HTTP::Cookies->new ;

    return $self;
}

sub _prepareVal {
    my ($self, $val) = @_;

    return '' unless length($val);

# forbid to long argument.
    while (length(URI::Escape::uri_escape_utf8($val)) > 1500) {
        $val =~ s/^.{5}/…/;
    }

    return URI::Escape::uri_escape_utf8($val);
}

sub send { ## no critic (ProhibitBuiltinHomonyms)
    my ($self, %params) = @_;

    my $url = ref $params{url} eq 'URI' ?
        $params{url} : URI->new($params{url});

    my $method = (exists($params{method}) && $params{method} =~ /^GET|POST$/) ?
        $params{method} : 'GET' ;

    my $urlparams = 'action='.uri_escape($params{args}->{action});
    my $referer = '';
    if ($method eq 'POST') {
        $referer = $url;
        $url .= '?'.$urlparams ;
        $url .= '&uuid='.uri_escape($params{args}->{uuid}) if (exists($params{args}->{uuid}));
        $url .= '&method=POST' ;
    }

    foreach my $k (keys %{$params{args}}) {
        if (ref($params{args}->{$k}) eq 'ARRAY') {
            foreach (@{$params{args}->{$k}}) {
                $urlparams .= '&'.$k.'[]='.$self->_prepareVal($_ || '');
            }
        } elsif (ref($params{args}->{$k}) eq 'HASH') {
            foreach (keys %{$params{args}->{$k}}) {
                $urlparams .= '&'.$k.'['.$_.']='.$self->_prepareVal($params{args}->{$k}{$_});
            }
        } elsif ($k ne 'action' && length($params{args}->{$k})) {
            $urlparams .= '&'.$k.'='.$self->_prepareVal($params{args}->{$k});
        }
    }

    $url .= '?'.$urlparams if ($method eq 'GET');

    $self->{logger}->debug2($url) if $self->{logger};

    my $request ;
    if ($method eq 'GET') {
        $request = HTTP::Request->new($method => $url);
    } else {
        $self->{logger}->debug2(_log_prefix."POST: ".$urlparams) if $self->{logger};
        my $headers = HTTP::Headers->new(
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Referer'      => $referer
        );
        $request = HTTP::Request->new(
            $method => $url,
            $headers,
            $urlparams
        );
        $self->{_cookies}->add_cookie_header( $request );
    }

    my $response = $self->request($request);

    return unless $response->is_success();

    $self->{_cookies}->extract_cookies($response);

    my $content = $response->content();
    unless ($content) {
        $self->{logger}->error( _log_prefix . "Got empty response" )
            if $self->{logger};
        return;
    }

    my $answer;
    eval {
        my $decoder = JSON::PP->new
            or die "Can't use JSON::PP decoder: $!";

        $answer = $decoder->decode($content);
    };

    if ($EVAL_ERROR && $self->{logger}) {
        my @lines = split(/\n/, $content);
        my $starting = '';
        while (@lines && length($starting) < 120) {
            my $line = getSanitizedString(shift(@lines));
            if (length($line) < 120) {
                $starting .= $line . "\n";
            } else {
                $starting .= substr($line, 0, 120) . " ...\n";
            }
        }
        $self->{logger}->error(
            _log_prefix . "Can't decode JSON content, starting with: " .
            $starting . (@lines ? "..." : "")
        ) if $starting;
        return;
    }

    return $answer;
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Client::Fusion - An HTTP client using Fusion protocol

=head1 DESCRIPTION

This is the object used by the agent to send messages to GLPI servers,
using new Fusion protocol (JSON messages sent through GET requests).

=head1 METHODS

=head2 send(%params)

The following parameters are allowed, as keys of the %params
hash:

=over

=item I<url>

the url to send the message to (mandatory)

=item I<args>

A list of parameters to pass to the server. The action key is mandatory.
Parameters can be hashref or arrayref.

=back

This method returns a perl data structure.
