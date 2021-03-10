package FusionInventory::Agent::SOAP::WsMan;

use strict;
use warnings;

use parent 'FusionInventory::Agent::HTTP::Client';

use XML::TreePP;
use HTTP::Request;
use HTTP::Headers;

use FusionInventory::Agent::SOAP::WsMan::Envelope;
use FusionInventory::Agent::SOAP::WsMan::Attribute;
use FusionInventory::Agent::SOAP::WsMan::Namespace;
use FusionInventory::Agent::SOAP::WsMan::Header;
use FusionInventory::Agent::SOAP::WsMan::Identify;
use FusionInventory::Agent::SOAP::WsMan::ResourceURI;
use FusionInventory::Agent::SOAP::WsMan::To;
use FusionInventory::Agent::SOAP::WsMan::ReplyTo;
use FusionInventory::Agent::SOAP::WsMan::Action;
use FusionInventory::Agent::SOAP::WsMan::MessageID;
use FusionInventory::Agent::SOAP::WsMan::MaxEnvelopeSize;
use FusionInventory::Agent::SOAP::WsMan::Locale;
use FusionInventory::Agent::SOAP::WsMan::DataLocale;
use FusionInventory::Agent::SOAP::WsMan::SessionId;
use FusionInventory::Agent::SOAP::WsMan::OperationID;
use FusionInventory::Agent::SOAP::WsMan::SequenceId;
use FusionInventory::Agent::SOAP::WsMan::OperationTimeout;
use FusionInventory::Agent::SOAP::WsMan::Enumerate;
use FusionInventory::Agent::SOAP::WsMan::Pull;
use FusionInventory::Agent::SOAP::WsMan::Option;
use FusionInventory::Agent::SOAP::WsMan::OptionSet;
use FusionInventory::Agent::SOAP::WsMan::Shell;
use FusionInventory::Agent::SOAP::WsMan::Signal;
use FusionInventory::Agent::SOAP::WsMan::Receive;
use FusionInventory::Agent::SOAP::WsMan::Code;

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
    $self->{logger}->debug($message) if $self->{logger};
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

    # Get response ignoring logging of error 500 as we would like to analyse it by ourself
    my $response = $self->request($request, undef, undef, undef, 500 => 1);

    $self->{_lastresponse} = $response;

    print STDERR "<====\n", $response->as_string, "<====\n" if $wsman_debug;

    if ( $response->is_success ) {
        my $tree = $tpp->parse($response->content);
        return $tree;
    } elsif ($response->header('Content-Type') && $response->header('Content-Type') =~ m{application/soap\+xml}) {
        # In case of failure (error 500) we can analyse the reason and log it
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
        Namespace->new(qw(s wsmid)),
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

    $self->debug2("Identify response: ".$identify->ProductVendor." - ".$identify->ProductVersion);

    return $identify;
}

sub enumerate {
    my ($self, $url) = @_;

    my @items;

    my $messageid = MessageID->new();
    my $sid = SessionId->new();
    my $operationid = OperationID->new();
    my $body = Body->new(Enumerate->new());
    my $action = Action->new("enumerate");

    $self->debug2("Requesting enumerate URL: $url");

    my $request = Envelope->new(
        Namespace->new(qw(s a n w p b)),
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
            $self->lasterror("Not an enumerate response but ".$respaction->what);
            last;
        }

        my $related = $header->get('RelatesTo');
        if (!$related || $related->string() ne $messageid->string()) {
            $self->lasterror("Got message not related to our enumeration request");
            last;
        }

        my $thisopid = $header->get('OperationID');
        unless ($thisopid && $thisopid->equals($operationid)) {
            $self->lasterror("Got message not related to our operation");
            last;
        }

        my $respbody = $envelope->body;
        unless (ref($respbody) eq 'Body') {
            $self->lasterror("Malformed enumerate response, no 'Body' node found");
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
        );
    }

    # Send End to remote
    $self->end($operationid);

    return @items;
}

sub shell {
    my ($self, $command) = @_;

    return unless $command;

    $self->debug2("Requesting '$command' run to ".$self->url);

    my $messageid = MessageID->new();
    my $sid = SessionId->new();
    my $operationid = OperationID->new();
    my $shell = Shell->new();
    my $action = Action->new("create");
    my $resource = ResourceURI->new("http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd");

    # WinRS option set
    my $optionset = OptionSet->new(
        Option->new( WINRS_NOPROFILE    => "TRUE" ),
        Option->new( WINRS_CODEPAGE     => "437" ),
    );

    # Create a remote shell
    my $request = Envelope->new(
        Namespace->new(qw(s a w p)),
        Header->new(
            To->new( $self->url ),
            $resource,
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
            $optionset,
        ),
        Body->new($shell),
    );

    my $response = $self->_send($request)
        or return;

    my $envelope = Envelope->new($response)
        or return;

    my $header = $envelope->header;
    return $self->abort("Malformed create response, no 'Header' node found")
        unless ref($header) eq 'Header';

    my $respaction = $header->action;
    return $self->abort("Malformed create response, no 'Action' found in Header")
        unless ref($respaction) eq 'Action';
    return $self->abort("Not a create response but ".$respaction->what)
        unless $respaction->is('createresponse');

    my $related = $header->get('RelatesTo');
    return $self->abort("Got message not related to our shell create request")
        if (!$related || $related->string() ne $messageid->string());

    my $thisopid = $header->get('OperationID');
    return $self->abort("Got message not related to our shell create operation")
        unless ($thisopid && $thisopid->equals($operationid));

    my $respbody = $envelope->body;
    return $self->abort("Malformed create response, no 'Body' node found")
        unless ref($respbody) eq 'Body';

    my $created = $respbody->get('ResourceCreated');
    return $self->abort("Malformed create response, no 'ResourceCreated' node found")
        unless ref($created) eq 'ResourceCreated';

    my $reference = $created->get('ReferenceParameters');
    return $self->abort("Malformed create response, no 'ReferenceParameters' returned")
        unless ref($reference) eq 'ReferenceParameters';

    my $selectorset = $reference->get('SelectorSet');
    return $self->abort("Malformed create response, no 'SelectorSet' returned")
        unless ref($selectorset) eq 'SelectorSet';

    # Setup command shell
    $messageid = MessageID->new();
    $operationid = OperationID->new();
    $action = Action->new("command");
    $optionset = OptionSet->new(
        Option->new( WINRS_CONSOLEMODE_STDIN => "TRUE" ),
    );
    $request = Envelope->new(
        Namespace->new(qw(s a w p)),
        Header->new(
            To->new( $self->url ),
            $resource,
            ReplyTo->anonymous,
            $action,
            $messageid,
            MaxEnvelopeSize->new(512000),
            Locale->new("en-US"),
            DataLocale->new("en-US"),
            $sid,
            $operationid,
            SequenceId->new(),
            $selectorset,
            OperationTimeout->new(60),
            $optionset,
        ),
        Body->new(
            $shell->commandline($command),
        ),
    );
    $response = $self->_send($request);
    return $self->abort("No command response")
        unless $response;

    $envelope = Envelope->new($response);
    return $self->abort("Malformed command response, no 'Envelope' node found")
        unless $envelope;

    $header = $envelope->header;
    return $self->abort("Malformed command response, no 'Header' node found")
        unless ref($header) eq 'Header';

    $respaction = $header->action;
    return $self->abort("Malformed command response, no 'Action' found in Header")
        unless ref($respaction) eq 'Action';
    return $self->abort("Not a command response but ".$respaction->what)
        unless $respaction->is('commandresponse');

    $related = $header->get('RelatesTo');
    return $self->abort("Got message not related to our shell command request")
        if (!$related || $related->string() ne $messageid->string());

    $thisopid = $header->get('OperationID');
    return $self->abort("Got message not related to our shell command operation")
        unless ($thisopid && $thisopid->equals($operationid));

    $respbody = $envelope->body;
    return $self->abort("Malformed command response, no 'Body' node found")
        unless ref($respbody) eq 'Body';

    my $respcmd = $respbody->get('CommandResponse');
    return $self->abort("Malformed command response, no 'CommandResponse' node found")
        unless ref($respcmd) eq 'CommandResponse';

    my $commandid = $respcmd->get('CommandId');
    return $self->abort("Malformed command response, no 'CommandId' returned")
        unless ref($commandid) eq 'CommandId';

    my $cid = $commandid->string();
    return $self->abort("Malformed command response, no CommandId value found")
        unless $cid;

    # Read stream from remote shell
    my $buffer = $self->receive($sid, $resource, $selectorset, $cid);
    my $exitcode = delete $self->{_exitcode} // 255;

    # Send terminate signal to shell
    $self->signal($sid, $resource, $selectorset, $cid, 'terminate');

    # Finally delete the shell resource
    $operationid = $self->delete($sid, $resource, $selectorset)
        or $self->error("Resource deletion failure");

    # Send End to remote
    $self->end($operationid) if $operationid;

    return {
        stdout      => \$buffer,
        exitcode    => $exitcode,
    };
}

sub receive {
    my ($self, $sid, $resource, $selectorset, $cid) = @_;

    my $stdout;

    while (1) {
        my $messageid = MessageID->new();
        my $operationid = OperationID->new();

        # Send Delete to remote
        my $request = Envelope->new(
            Namespace->new(qw(s a w p)),
            Header->new(
                To->new( $self->url ),
                $resource,
                ReplyTo->anonymous,
                Action->new("receive"),
                $messageid,
                MaxEnvelopeSize->new(512000),
                Locale->new("en-US"),
                DataLocale->new("en-US"),
                $sid,
                $operationid,
                SequenceId->new(),
                OperationTimeout->new(60),
                $selectorset,
            ),
            Body->new( Receive->new($cid) ),
        );

        my $response = $self->_send($request)
            or last;

        my $envelope = Envelope->new($response)
            or last;

        my $header = $envelope->header;
        $self->abort("Malformed receive response, no 'Header' node found") and last
            unless ref($header) eq 'Header';

        my $action = $header->action;
        $self->abort("Malformed receive response, no 'Action' found in Header") and last
            unless ref($action) eq 'Action';
        $self->abort("Not a receive response but ".$action->what) and last
            unless $action->is('receiveresponse');

        my $related = $header->get('RelatesTo');
        $self->abort("Got message not related to receive request") and last
            if (!$related || $related->string() ne $messageid->string());

        my $thisopid = $header->get('OperationID');
        $self->abort("Got message not related to receive operation") and last
            unless ($thisopid && $thisopid->equals($operationid));

        my $body = $envelope->body;
        $self->lasterror("Malformed receive response, no 'Body' node found") and last
            unless (ref($body) eq 'Body');

        my $received = $body->get('ReceiveResponse');
        $self->lasterror("Malformed receive response, no 'ReceiveResponse' node found") and last
            unless (ref($received) eq 'ReceiveResponse');

        my $cmdstate = $received->get('CommandState');
        $self->lasterror("Malformed receive response, no 'CommandState' node found") and last
            unless (ref($cmdstate) eq 'CommandState');

        my $streams = $received->get('Stream');
        $self->lasterror("Malformed receive response, no 'Stream' node found") and last
            unless (ref($streams) eq 'Stream');

        # Handles Streams
        my $stderr = $streams->stderr($cid);
        $stdout .= $streams->stdout($cid);

        if (defined($stderr) && length($stderr)) {
            foreach my $line (split(/\n/m, $stderr)) {
                chomp $line;
                $self->debug2("Command stderr: $line");
            }
        }

        my $exitcode = $cmdstate->exitcode();
        if (defined($exitcode)) {
            $self->debug2("Command exited with code: $exitcode");
            $self->debug2("Command stdout seems truncated") unless $streams->stdout_is_full($cid);
            $self->debug2("Command stderr seems truncated") unless $streams->stderr_is_full($cid);
            $self->{_exitcode} = $exitcode;
        }

        last if $cmdstate->done($cid);
    }

    return $stdout;
}

sub signal {
    my ($self, $sid, $resource, $selectorset, $cid, $signal) = @_;

    my $messageid = MessageID->new();
    my $operationid = OperationID->new();

    # Send Delete to remote
    my $request = Envelope->new(
        Namespace->new(qw(s a w p)),
        Header->new(
            To->new( $self->url ),
            $resource,
            ReplyTo->anonymous,
            Action->new("signal"),
            $messageid,
            MaxEnvelopeSize->new(512000),
            Locale->new("en-US"),
            DataLocale->new("en-US"),
            $sid,
            $operationid,
            SequenceId->new(),
            OperationTimeout->new(60),
            $selectorset,
        ),
        Body->new(
            Signal->new(
                Attribute->new( "xmlns:".Shell->xmlns => Shell->xsd ),
                Attribute->new( CommandId => $cid ),
                Code->signal($signal),
            ),
        ),
    );

    my $response = $self->_send($request)
        or return;

    my $envelope = Envelope->new($response)
        or return;

    my $header = $envelope->header;
    return $self->abort("Malformed signal response, no 'Header' node found")
        unless ref($header) eq 'Header';

    my $respaction = $header->action;
    return $self->abort("Malformed signal response, no 'Action' found in Header")
        unless ref($respaction) eq 'Action';
    return $self->abort("Not a signal response but ".$respaction->what)
        unless $respaction->is('signalresponse');

    my $related = $header->get('RelatesTo');
    return $self->abort("Got message not related to signal request")
        if (!$related || $related->string() ne $messageid->string());

    my $thisopid = $header->get('OperationID');
    return $self->abort("Got message not related to signal operation")
        unless ($thisopid && $thisopid->equals($operationid));
}

sub delete {
    my ($self, $sid, $resource, $selectorset) = @_;

    my $messageid = MessageID->new();
    my $operationid = OperationID->new();

    # Send Delete to remote
    my $request = Envelope->new(
        Namespace->new(qw(s a w p)),
        Header->new(
            To->new( $self->url ),
            $resource,
            ReplyTo->anonymous,
            Action->new("delete"),
            $messageid,
            MaxEnvelopeSize->new(512000),
            Locale->new("en-US"),
            DataLocale->new("en-US"),
            $sid,
            $operationid,
            SequenceId->new(),
            OperationTimeout->new(60),
            $selectorset,
        ),
        Body->new(),
    );

    my $response = $self->_send($request)
        or return;

    my $envelope = Envelope->new($response)
        or return;

    my $header = $envelope->header;
    return $self->abort("Malformed delete response, no 'Header' node found")
        unless ref($header) eq 'Header';

    my $respaction = $header->action;
    return $self->abort("Malformed delete response, no 'Action' found in Header")
        unless ref($respaction) eq 'Action';
    return $self->abort("Not a delete response but ".$respaction->what)
        unless $respaction->is('deleteresponse');

    my $related = $header->get('RelatesTo');
    return $self->abort("Got message not related to delete request")
        if (!$related || $related->string() ne $messageid->string());

    my $thisopid = $header->get('OperationID');
    return $self->abort("Got message not related to delete operation")
        unless ($thisopid && $thisopid->equals($operationid));

    return $operationid;
}

sub end {
    my ($self, $operationid) = @_;

    # Send End to remote
    my $request = Envelope->new(
        Namespace->new(qw(s a w p)),
        Header->new(
            To->anonymous,
            ResourceURI->new( "http://schemas.microsoft.com/wbem/wsman/1/wsman/FullDuplex" ),
            Action->new("end"),
            MessageID->new(),
            $operationid,
        ),
        Body->new(),
    );
    $self->_send($request);
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
