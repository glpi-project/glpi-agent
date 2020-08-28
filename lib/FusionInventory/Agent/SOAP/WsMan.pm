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
        _ua     => $params{ua},
        _config => $params{config} // {},
    };
    bless $self, $class;

    $tpp = XML::TreePP->new() unless $tpp;

    return $self;
}

sub _ua {
    my ($self) = @_;

    # create user agent only if timeout is defined
    return unless $self->{_config}->{timeout};

    unless ($self->{_ua}) {
        $self->{_ua} = LWP::UserAgent->new(
            requests_redirectable => ['POST', 'GET', 'HEAD'],
            agent                 => $self->{_config}->{useragent} // $FusionInventory::Agent::AGENT_STRING,
            timeout               => $self->{_config}->{timeout},
            parse_head            => 0, # No need to parse HTML
            keep_alive            => 1,
            cookie_jar            => HTTP::Cookies->new(ignore_discard => 1),
        );

        if ($self->url() =~ /ĥttps:/) {
            $self->{_ua}->ssl_opts(SSL_ca_file => $self->{_config}->{'ca-cert-file'} || $ENV{'CA_CERT_FILE'})
                if $self->{_config}->{'ca-cert-file'} || $ENV{'CA_CERT_FILE'};
            $self->{_ua}->ssl_opts(SSL_cert_file => $self->{_config}->{'ssl-cert-file'} || $ENV{'SSL_CERT_FILE'})
                if $self->{_config}->{'ssl-cert-file'} || $ENV{'SSL_CERT_FILE'};
            $self->{_ua}->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0)
                if $self->{_config}->{'no-ssl-check'};
        }
    }

    return $self->{_ua};
}

sub _send {
    my ( $self, $xml, %headers ) = @_;

    my $headers = HTTP::Headers->new(
        'Content-Type'      => 'application/soap+xml; charset=utf-8',
        'Content-length'    => length($xml // ''),
        %headers,
    );

    my $request = HTTP::Request->new( POST => $self->url(), $headers, $xml );

    my $response = $self->_ua()->request($request);

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
