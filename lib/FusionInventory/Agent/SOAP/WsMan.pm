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

sub new {
    my ($class, %params) = @_;

    my $self = {
        url => $params{url},
        tpp => XML::TreePP->new(),
    };
    bless $self, $class;

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

    my $request = HTTP::Request->new( POST => $self->{url}, $headers, $xml );

    my $response = $self->{ua}->request($request);

    $self->{_lastresponse} = $response;

    if ( $response->is_success ) {
        my $tree = $self->{tpp}->parse($response->content);
        return $tree;
    } else {
        my $status = $response->status_line;
        $self->{_lasterror} = $status;
        return;
    }
}

sub identify {
    my ($self) = @_;

    my $request = Envelope->new(
        Attribute->new(
            'xmlns:wsmid' => "https://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"
        ),
        Header->new(
            Body->new( 'wsmid:Identify' => '' ),
        ),
    );

    my $response = $self->_send(
        $self->{tpp}->write($request->get()),
        WSMANIDENTIFY => 'unauthenticated',
    );

    return unless $response;

    my $identify = Envelope->new($response);

    # TODO Verify the identify response
}

1;
