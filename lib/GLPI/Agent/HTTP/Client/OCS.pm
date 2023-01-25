package GLPI::Agent::HTTP::Client::OCS;

use strict;
use warnings;
use parent 'GLPI::Agent::HTTP::Client';

use English qw(-no_match_vars);
use HTTP::Request;
use UNIVERSAL::require;
use URI;
use Encode;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::UUID;
use GLPI::Agent::XML::Response;

use constant    _log_prefix => "[http client] ";

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    $self->{ua}->default_header('Pragma' => 'no-cache');

    # Fix content-type header when not compressing
    $self->{ua}->default_header('Content-type' => 'application/xml')
        if $self->{compression} eq 'none';

    # GLPI Agent will advertize it supports GLPI protocol by sending its agentid
    # via GLPI-Agent-ID HTTP header. Legacy plugins will simply ignore it.
    $self->{ua}->default_header(
        'GLPI-Agent-ID' => is_uuid_string($params{agentid}) ?
            $params{agentid} : uuid_to_string($params{agentid})
    )
        if defined($params{agentid});

    return $self;
}

sub send { ## no critic (ProhibitBuiltinHomonyms)
    my ($self, %params) = @_;

    my $url = ref $params{url} eq 'URI' ?
        $params{url} : URI->new($params{url});
    my $message = $params{message};
    my $logger  = $self->{logger};

    my $request_content = $message->getContent();
    $logger->debug2(_log_prefix . "sending message:\n$request_content");

    $request_content = $self->compress(encode('UTF-8', $request_content));
    if (!$request_content) {
        $logger->error(_log_prefix . 'inflating problem');
        return;
    }

    my $request = HTTP::Request->new(POST => $url);
    $request->content($request_content);

    my $response = $self->request($request);

    # no need to log anything specific here, it has already been done
    # in parent class
    return if !$response->is_success();

    my $response_content = $response->content();
    if (!$response_content) {
        $logger->error(_log_prefix . "unknown content format");
        return;
    }

    my $type = $response->header("Content-type") // "text/plain";
    my $uncompressed_response_content = $type =~ m{^application/x-}i ? $self->uncompress($response_content, $type) : $response_content;
    if (!$uncompressed_response_content) {
        $logger->error(
            _log_prefix . "can't uncompress content starting with: ".substr($response_content, 0, 500)
        );
        return;
    }

    $logger->debug2(_log_prefix . "receiving message:\n$uncompressed_response_content");

    my $result;
    eval {
        $result = GLPI::Agent::XML::Response->new(
            content => $uncompressed_response_content
        );
    };
    if ($EVAL_ERROR && $uncompressed_response_content =~ /^\{.*\}$/s) {
        # When the GLPI Agent first contact a GLPI server with the legacy OCS protocol
        # it can receive directly a CONTACT JSON answer
        GLPI::Agent::Protocol::Contact->require();
        if ($EVAL_ERROR) {
            $logger->error("Can't load GLPI CONTACT Protocol support, you probably miss a perl library dependency");
        } else {
            my $contact;
            eval {
                $contact = GLPI::Agent::Protocol::Contact->new(
                    message => $uncompressed_response_content,
                );
            };
            return $contact if defined($contact) && $contact->is_valid_message;
            if ($contact->status eq 'pending') {
                $logger->debug("Got GLPI CONTACT pending answer");
                return $contact;
            } else {
                $logger->debug("Not a GLPI CONTACT message");
            }
        }
    }
    unless (defined($result)) {
        if ($uncompressed_response_content =~ /Inventory is disabled/i) {
            $logger->warning(
                _log_prefix . "Inventory support is disabled server-side"
            );
        } else {
            my @lines = split(/\n/, substr($uncompressed_response_content,0,120));
            $logger->error(
                _log_prefix . "unexpected content, starting with: $lines[0]"
            );
        }
        return;
    }

    return $result;
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Client::OCS - An HTTP client using OCS protocol

=head1 DESCRIPTION

This is the object used by the agent to send messages to OCS or GLPI servers,
using original OCS protocol (XML messages sent through POST requests).

=head1 METHODS

=head2 send(%params)

Send an instance of C<GLPI::Agent::XML::Query> to the target (the
server).

The following parameters are allowed, as keys of the %params
hash:

=over

=item I<url>

the url to send the message to (mandatory)

=item I<message>

the message to send (mandatory)

=back

This method returns an C<GLPI::Agent::XML::Response> instance.
