package FusionInventory::Agent::SOAP::WsMan;

use strict;
use warnings;

use English qw(-no_match_vars);
use XML::TreePP;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Headers;

use FusionInventory::Agent::SOAP::WsMan::Envelope;
use FusionInventory::Agent::SOAP::WsMan::Attribute;
use FusionInventory::Agent::SOAP::WsMan::Header;
use FusionInventory::Agent::SOAP::WsMan::Identify;

my $tpp;

sub new {
    my ($class, %params) = @_;

    my $self = {
        _url    => $params{url},
    };
    bless $self, $class;

    $tpp = XML::TreePP->new() unless $tpp;

    # create user agent
    $self->{ua} = LWP::UserAgent->new(
        requests_redirectable => ['POST', 'GET', 'HEAD'],
        agent                 => $FusionInventory::Agent::AGENT_STRING,
        timeout               => $params{timeout} || 180,
        ssl_opts              => { verify_hostname => 0, SSL_verify_mode => 0 },
        cookie_jar            => HTTP::Cookies->new(ignore_discard => 1),
    );

    return $self;
}

sub _send {
    my ( $self, $xml, %headers ) = @_;

    my $headers = HTTP::Headers->new(
        'Content-Type'      => 'application/soap+xml; charset=utf-8',
        'Content-length'    => length($xml // ''),
        %headers,
    );

    my $request = HTTP::Request->new( POST => $self->url(), $headers, $xml );

    my $response = $self->{ua}->request($request);

    $self->{_lastresponse} = $response;

    if ( $response->is_success ) {
        my $tree = $tpp->parse($response->content);
        return $tree;
    } else {
        my $status = $response->status_line;
        $self->lasterror($status);
        return;
    }
}

sub identify {
    my ($self) = @_;

    my $request = Envelope->new(
        Attribute->new( Identify->namespace ),
        Header->new(
            Body->new( Identify->request ),
        ),
    );

    my $response = $self->_send(
        $tpp->write($request->get()),
        WSMANIDENTIFY => 'unauthenticated',
    );

    return unless $response;

    my $envelope = Envelope->new($response);
    my $body = $envelope->body;
    unless (ref($body) eq 'Body') {
        $self->lasterror("Malformed identify response, no 'body' node found");
        return;
    }

    my $identify = $body->get("Identify");
    unless ($identify->isvalid) {
        $self->lasterror("Malformed identify response, not valid");
        return;
    }

    return $identify;
}

sub lasterror {
    my ($self, $error) = @_;

    $self->{_lasterror} = $error if defined($error);

    return $self->{_lasterror} // '';
}

sub url {
    my ($self) = @_;

    return $self->{_url};
}

1;
