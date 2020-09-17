package FusionInventory::Agent::SOAP::WsMan;

use strict;
use warnings;

use parent 'FusionInventory::Agent::HTTP::Client';

use XML::TreePP;
use HTTP::Request;
use HTTP::Headers;

use FusionInventory::Agent::SOAP::WsMan::Envelope;
use FusionInventory::Agent::SOAP::WsMan::Attribute;
use FusionInventory::Agent::SOAP::WsMan::Header;
use FusionInventory::Agent::SOAP::WsMan::Identify;
use FusionInventory::Agent::SOAP::WsMan::ResourceURI;
use FusionInventory::Agent::SOAP::WsMan::To;
use FusionInventory::Agent::SOAP::WsMan::ReplyTo;
use FusionInventory::Agent::SOAP::WsMan::Address;
use FusionInventory::Agent::SOAP::WsMan::Action;
use FusionInventory::Agent::SOAP::WsMan::MessageID;
use FusionInventory::Agent::SOAP::WsMan::MaxEnvelopeSize;
use FusionInventory::Agent::SOAP::WsMan::Locale;
use FusionInventory::Agent::SOAP::WsMan::DataLocale;
use FusionInventory::Agent::SOAP::WsMan::SessionId;
use FusionInventory::Agent::SOAP::WsMan::OperationID;
use FusionInventory::Agent::SOAP::WsMan::SequenceId;
use FusionInventory::Agent::SOAP::WsMan::OperationTimeout;
use FusionInventory::Agent::SOAP::WsMan::SelectorSet;
use FusionInventory::Agent::SOAP::WsMan::Selector;
use FusionInventory::Agent::SOAP::WsMan::Enumerate;
use FusionInventory::Agent::SOAP::WsMan::Pull;

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
    $self->{_noauth} = $params{user} && $params{password} ? 0 : 1;

    bless $self, $class;

    $tpp = XML::TreePP->new() unless $tpp;

    # Don't send XML declaration, everything is in the Content-Type header
    $tpp->set( xml_decl => '' );

    $tpp->set( first_out => [ 's:Header' ] );

    return $self;
}

sub abort {
    my ( $self, $message ) = @_;
    $self->lasterror($message);
    $self->{logger}->error($message) if $self->{logger};
    return;
}

sub debug {
    my ( $self, $message ) = @_;
    $self->{logger}->debug($message) if $self->{logger};
}

sub debug2 {
    my ( $self, $message ) = @_;
    $self->{logger}->debug2($message) if $self->{logger};
}

sub _send {
    my ( $self, $envelope, $header ) = @_;

    my $xml = $tpp->write($envelope->get());
    return $self->abort("Won't send wrong request")
        unless $xml;

    my $headers = HTTP::Headers->new(
        'Content-Type'      => 'application/soap+xml;charset=UTF-8',
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
        if ($envelope->header->action->is("fault")) {
            my $text = $envelope->body->fault->reason->text;
            return $self->abort($text || $response->status_line);
        }
    }

    unless ( $response->is_success ) {
        my $status = $response->status_line;
        return $self->abort($status);;
    }
}

sub identify {
    my ($self) = @_;

    my $request = Envelope->new(
        namespace   =>"s,wsmid",
        Header->new(),
        Body->new( Identify->new() ),
    );

    my $response = $self->_send(
        $request,
        $self->{_winrm} && $self->{_noauth} ? { WSMANIDENTIFY => 'unauthenticated' } : {},
    );

    return unless $response;

    my $envelope = Envelope->new($response);
    my $body = $envelope->body;
    return $self->abort("Malformed identify response, no 'body' node found")
        unless (ref($body) eq 'Body');

    my $identify = $body->get("IdentifyResponse");
    return $self->abort("Malformed identify response, not valid")
        unless $identify->isvalid();

    $self->debug2("Identify response: ".$identify->get("ProductVendor")." - ".$identify->get("ProductVersion"));

    return $identify;
}

sub resource {
    my ($self, $url) = @_;

    my $messageid = MessageID->new();
    my $sid = SessionId->new();
    my $operationid = OperationID->new();

    my $request = Envelope->new(
        namespace   => "s,a,w,p",
        Header->new(
            To->new( $self->url ),
            ResourceURI->new( $url ),
            ReplyTo->anonymous,
            Action->new("get"),
            $messageid,
            MaxEnvelopeSize->new(512000),
            Locale->new("en-US"),
            DataLocale->new("en-US"),
            $sid,
            $operationid,
            SequenceId->new(),
            OperationTimeout->new(60),
            SelectorSet->new(
                Selector->new()
            ),
        ),
        Body->new(),
    );

    my $response = $self->_send($request);

    return unless $response;

    my $envelope = Envelope->new($response);

    my $body = $envelope->body;
    unless (ref($body) eq 'Body') {
        $self->lasterror("Malformed resource response, no 'body' node found");
        return;
    }
}

sub enumerate {
    my ($self, $url) = @_;

    my @items;

    my $messageid = MessageID->new();
    my $sid = SessionId->new();
    my $operationid = OperationID->new();
    my $body = Body->new(Enumerate->new());
    my $action = Action->new("enumerate");

    my $request = Envelope->new(
        namespace   => "s,a,n,w,p,b",
        Header->new(
            To->new( $self->url ),
            ResourceURI->new( $url ),
            ReplyTo->anonymous,
            $action,
            $messageid,
            MaxEnvelopeSize->new(512000),
            Locale->new("en-US"),
            DataLocale->new("en-US"),
            $sid,
            $operationid,
            SequenceId->new(),
            OperationTimeout->new(60),
        ),
        $body,
    );

    my $response;

    while ($request) {
        $response = $self->_send($request)
            or last;

        my $envelope = Envelope->new($response)
            or last;

        my $header = $envelope->header;
        unless (ref($header) eq 'Header') {
            $self->lasterror("Malformed enumerate response, no 'Header' node found");
            last;
        }

        my $respaction = $header->action;
        unless (ref($respaction) eq 'Action') {
            $self->lasterror("Malformed enumerate response, no 'Action' found in Header");
            last;
        }
        my $ispull = $respaction->is('pullresponse');
        unless ($ispull || $respaction->is('enumerateresponse')) {
            $self->lasterror("Not an enumerate response but ".$action->what);
            last;
        }

        my $related = $header->get('RelatesTo');
        if (!$related || $related->string() ne $messageid->string()) {
            $self->lasterror("Got message not related to our enumeration request");
            last;
        }

        my $thisopid = $header->get('OperationID');
        if (!$thisopid || $thisopid->string() ne $operationid->string()) {
            $self->lasterror("Got message not related to our operation");
            last;
        }

        my $respbody = $envelope->body;
        unless (ref($respbody) eq 'Body') {
            $self->lasterror("Malformed enumerate response, no 'body' node found");
            last;
        }

        my $enum = $respbody->enumeration($ispull);
        push @items, $enum->items;

        last if $enum->end_of_sequence;

        # Fix Envelope namespaces
        $request->reset_namespace("s,a,n,w,p");

        # Update Action to Pull
        $action->set("pull");

        # Update MessageID & OperationID
        $messageid->reset_uuid();
        $operationid->reset_uuid();

        # Reset Body to make Pull request with provided EnumerationContext
        $body->reset(
            Pull->new( $enum->context )
        )
    }

    # Send End to remote
    $request = Envelope->new(
        namespace   => "s,a,w,p",
        Header->new(
            To->anonymous,
            ResourceURI->new( "http://schemas.microsoft.com/wbem/wsman/1/wsman/FullDuplex" ),
            Action->new("end"),
            MessageID->new(),
            $operationid,
        ),
        Body->new(),
    );
    $response = $self->_send($request);

    return @items;
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
