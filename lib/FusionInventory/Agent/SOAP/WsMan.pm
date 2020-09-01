package FusionInventory::Agent::SOAP::WsMan;

use strict;
use warnings;

use parent 'FusionInventory::Agent::HTTP::Client';

use English qw(-no_match_vars);
use URI;
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
my $wsman_debug = $ENV{WSMAN_DEBUG} ? 1 : 0;

sub new {
    my ($class, %params) = @_;

    my $config = $params{config} // {};

    my $self = $class->SUPER::new(
        timeout         => $config->{timeout},
        no_ssl_check    => $config->{no_ssl_check},
        ca_cert_dir     => $config->{ca_cert_dir}   || $ENV{'CA_CERT_PATH'},
        ca_cert_file    => $config->{ca_cert_file}  || $ENV{'CA_CERT_FILE'},
        ssl_cert_file   => $config->{ssl_cert_file} || $ENV{'SSL_CERT_FILE'},
        %params,
    );

    $self->{_url} = $params{url};
    $self->{_winrm} = $params{winrm} // 0;

    bless $self, $class;

    $tpp = XML::TreePP->new() unless $tpp;

    return $self;
}

sub _send {
    my ( $self, $xml, $header ) = @_;

    my $headers = HTTP::Headers->new(
        'Content-Type'      => 'application/soap+xml; charset=utf-8',
        'Content-length'    => length($xml // ''),
        %{$header},
    );

    my $request = HTTP::Request->new( POST => $self->url(), $headers, $xml );

    print STDERR "===>\n", $request->as_string, "===>\n" if $wsman_debug;

    my $response = $self->request($request);

    $self->{_lastresponse} = $response;

    print STDERR "<====\n", $response->as_string, "<====\n" if $wsman_debug;

    if ( $response->is_success ) {
        my $tree = $tpp->parse($response->content);
        return $tree;
    } elsif ($response->header('Content-Type') && $response->header('Content-Type') =~ m{application/soap\+xml}) {
        my $tree = $tpp->parse($response->content);
        my $envelope = Envelope->new($tree);
        if ($envelope->header->action eq "http://schemas.xmlsoap.org/ws/2004/08/addressing/fault") {
            my $text = $envelope->body->fault->reason->text;
            $self->lasterror($text || $response->status_line);
            return;
        }
    }

    unless ( $response->is_success ) {
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
        $self->{_winrm} ? { WSMANIDENTIFY => 'unauthenticated' } : {},
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
