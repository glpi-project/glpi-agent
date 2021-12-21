package GLPI::Agent::HTTP::Client::GLPI;

use strict;
use warnings;
use parent 'GLPI::Agent::HTTP::Client';

use English qw(-no_match_vars);
use HTTP::Request;
use UNIVERSAL::require;
use URI;
use Encode;

use GLPI::Agent::Tools;
use GLPI::Agent::Logger;
use GLPI::Agent::Tools::UUID;

use GLPI::Agent::Protocol::Message;

my $requestid;
sub _log_prefix {
    return $requestid ? "[http client] $requestid: " : "[http client] ";
}

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    $self->{ua}->default_header('Pragma' => 'no-cache');

    # Set requestid if in debug mode
    if ($self->{logger}->debug_level()) {
        $requestid = join('', map { sprintf("%02X", int(rand(256))) } 1..4);
    } else {
        undef $requestid;
    }

    # check compression mode
    if (!$self->{no_compress} && Compress::Zlib->require()) {
        # RFC 1950
        $self->{compression} = 'zlib';
        $self->{logger}->debug(_log_prefix."Using Compress::Zlib for compression");
    } elsif (!$self->{no_compress} && canRun('gzip')) {
        # RFC 1952
        $self->{compression} = 'gzip';
        $self->{logger}->debug(_log_prefix."Using gzip for compression");
    } else {
        $self->{compression} = 'none';
        $self->{logger}->debug(_log_prefix."Not using compression");
    }

    # Set content-type header relative to selected compression
    $self->{ua}->default_header('Content-type' =>
        $self->{compression} eq 'zlib' ? "application/x-compress-zlib" :
        $self->{compression} eq 'gzip' ? "application/x-compress-gzip" :
                                         "application/json"
    );

    $self->{ua}->default_header(
        'GLPI-Agent-ID' => is_uuid_string($params{agentid}) ?
            $params{agentid} : uuid_to_string($params{agentid})
    )
        if defined($params{agentid});

    $self->{ua}->default_header('GLPI-Proxy-ID' => $params{proxyid})
        if defined($params{proxyid});

    $self->{ua}->default_header('GLPI-Request-ID' => $requestid) if $requestid;

    return $self;
}

sub send { ## no critic (ProhibitBuiltinHomonyms)
    my ($self, %params) = @_;

    my $logger = $self->{logger};

    # Always check we have a valid agentid set
    my $agentid = $self->{ua}->default_header('GLPI-Agent-ID');
    unless (is_uuid_string($agentid)) {
        $logger->error(_log_prefix . 'no valid agentid set on HTTP client');
        return;
    }

    my $url = ref($params{url}) eq 'URI' ? $params{url} : URI->new($params{url});
    my $message = ref($params{message}) eq 'HASH' ?
        GLPI::Agent::Protocol::Message->new(
            message => $params{message},
        )
        : $params{message};

    my $request_content = $message->getContent();
    $logger->debug2(_log_prefix . "sending message:\n$request_content");

    $request_content = $self->_compress(encode('UTF-8', $request_content));
    unless ($request_content) {
        $logger->error(_log_prefix . 'inflating problem');
        return;
    }
    my $request = HTTP::Request->new(POST => $url);
    $request->content($request_content);

    my $answer;
    my $try = 1;
    while (!defined($answer)) {
        # Initialze a new message to be updated by the answer
        $answer = GLPI::Agent::Protocol::Message->new();
        my $response = $self->request($request);

        $requestid = $response->header("GLPI-Request-ID");
        undef $requestid unless defined($requestid) && $requestid =~ /^[0-9A-F]{8}$/;

        my $content = $response->content();
        unless (defined($content)) {
            $logger->error(_log_prefix . "no answer content") if $response->is_success();
            return;
        }

        my $type = $response->header("Content-type") // "";
        my $uncompressed_response_content = $self->_uncompress($content, $type);
        unless ($uncompressed_response_content) {
            unless (length($content)) {
                $logger->error(_log_prefix . "Got empty answer") if $response->is_success();
                return;
            }
            $logger->error(
                _log_prefix . "uncompressed content, starting with: ".substr($content, 0, 120)
            );
            return;
        }

        $logger->debug2(_log_prefix . "receiving message:\n$uncompressed_response_content");

        eval {
            $answer->set($uncompressed_response_content);
        };
        if ($EVAL_ERROR) {
            my @lines = split(/\n/, substr($uncompressed_response_content, 0, 120));
            $logger->error(_log_prefix . "unexpected content, starting with: $lines[0]");
            return;
        }
        unless ($answer->is_valid_message()) {
            $logger->error(_log_prefix . "not a valid answer");
            return;
        }

        # log server error message is set
        if ($answer->status eq 'error' || !$response->is_success()) {
            my $message = $answer->get('message');
            $logger->error(_log_prefix . "server error: $message")
                if $message;
            return;
        }

        # Handle pending case with 12 retries max, but don't if handled in caller
        if ($answer->status eq 'pending' && (!$params{pending} || $params{pending} ne "pass")) {
            if (++$try>12) {
                $logger->error(_log_prefix . "got too much pending status");
                return;
            }
            sleep $answer->expiration;
            $logger->debug2(_log_prefix . "retry request after pending status");
            undef $answer;
            # Next request should be a GET with expected RequestID and no content
            $request->method("GET");
            $request->content("");
            $request->header( "GLPI-Request-ID" => $requestid ) if $requestid;
        }
    }

    return $answer;
}

sub _compress {
    my ($self, $data) = @_;

    return
        $self->{compression} eq 'zlib' ? Compress::Zlib::compress($data) :
        $self->{compression} eq 'gzip' ? $self->_compressGzip($data)     :
                                         $data;
}

sub _uncompress {
    my ($self, $data, $type) = @_;

    return unless defined($type);

    $type =~ s|^application/||i;

    if ($type =~ /^x-compress-zlib$/i) {
        $self->{logger}->debug2("format: Zlib");
        return Compress::Zlib::uncompress($data);
    } elsif ($type =~ /^x-compress-gzip$/i) {
        $self->{logger}->debug2("format: Gzip");
        return $self->_uncompressGzip($data);
    } elsif ($type =~ /^json$/i) {
        $self->{logger}->debug2("format: JSON");
        return $data;
    } else {
        $self->{logger}->debug2("unsupported format: $type");
        return;
    }
}

sub _compressGzip {
    my ($self, $data) = @_;

    File::Temp->require();
    my $in = File::Temp->new();
    print $in $data;
    close $in;

    my $out = getFileHandle(
        command => 'gzip -c ' . $in->filename(),
        logger  => $self->{logger}
    );
    return unless $out;

    local $INPUT_RECORD_SEPARATOR; # Set input to "slurp" mode.
    my $result = <$out>;
    close $out;

    return $result;
}

sub _uncompressGzip {
    my ($self, $data) = @_;

    my $in = File::Temp->new();
    print $in $data;
    close $in;

    my $out = getFileHandle(
        command => 'gzip -dc ' . $in->filename(),
        logger  => $self->{logger}
    );
    return unless $out;

    local $INPUT_RECORD_SEPARATOR; # Set input to "slurp" mode.
    my $result = <$out>;
    close $out;

    return $result;
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Client::GLPI - HTTP client supporting GLPI Agent protocol

=head1 DESCRIPTION

This is the object used by the agent to send messages to GLPI servers
using dedicated GLPI Agent protocol (JSON messages sent through POST requests).

=head1 METHODS

=head2 send(%params)

Send a JSON content to the target (a server or a proxy agent).

The following parameters are allowed, as keys of the %params
hash:

=over

=item I<url>

the url to send the message to (mandatory)

=item I<message>

the message to send (mandatory)

=back

This method returns a GLPI:Agent::Message object.
