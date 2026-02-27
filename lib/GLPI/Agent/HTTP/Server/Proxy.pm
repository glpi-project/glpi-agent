package GLPI::Agent::HTTP::Server::Proxy;

use strict;
use warnings;

use English qw(-no_match_vars);
use Compress::Zlib;
use File::Temp;

use base "GLPI::Agent::HTTP::Server::Plugin";

use GLPI::Agent::Tools;
use GLPI::Agent::XML;
use GLPI::Agent::Tools::UUID;
use GLPI::Agent::HTTP::Client;
use GLPI::Agent::HTTP::Client::OCS;
use GLPI::Agent::HTTP::Client::GLPI;

use GLPI::Agent::Protocol::Message;
use GLPI::Agent::Protocol::Answer;

use GLPI::Agent::HTTP::Server::Proxy::Message;
use GLPI::Agent::HTTP::Server::Proxy::Reply;

our $VERSION = "3.0";

sub urlMatch {
    my ($self, $path) = @_;
    # By default, re_path_match => qr{^/proxy/(apiversion|glpi)/?$}
    return 0 unless $path =~ $self->{re_path_match};
    $self->{request} = $1;
    return 1;
}

my $requestid;
sub log_prefix {
    return defined($requestid) && length($requestid) ?
        "[proxy server plugin] $requestid: " : "[proxy server plugin] " ;
}

sub config_file {
    return "proxy-server-plugin.cfg";
}

sub defaults {
    return {
        disabled            => "yes",
        url_path            => "/proxy",
        port                => 0,
        only_local_store    => "no",
        local_store         => '',
        prolog_freq         => 24,
        max_proxy_threads   => 10,
        max_pass_through    => 5,
        glpi_protocol       => "yes",
        no_category         => "",
        # Supported by class GLPI::Agent::HTTP::Server::Plugin
        maxrate             => 30,
        maxrate_period      => 3600,
        forbid_not_trusted  => "no",
    };
}

# Don't publish an url on glpi-agent index page
sub url {}

sub supported_method {
    my ($self, $method) = @_;

    return 1 if $method eq 'GET' || $method eq 'POST';

    $self->error("invalid request type: $method");

    return 0;
}

sub init {
    my ($self) = @_;

    $self->SUPER::init(@_);

    # Don't do more initialization if disabled
    return if $self->disabled();

    $self->{request}  = 'none';

    my $defaults = $self->defaults();
    my $url_path = $self->config('url_path');
    $self->debug("Using $url_path as base url matching")
        if ($url_path ne $defaults->{url_path});
    $self->{re_path_match} = qr{^$url_path/(apiversion|glpi)/?$};

    # Normalize only_local_store
    $self->{only_local_store} = $self->config('only_local_store') !~ /^0|no$/i ? 1 : 0;
    $self->{glpi_protocol}    = $self->config('glpi_protocol')    !~ /^0|no$/i ? 1 : 0;

    # Set finally we will only store locally if no server is indeed configured and glpi_protocol is set
    if ($self->config('glpi_protocol') && scalar(grep { $_->isType('server') } $self->{server}->{agent}->getTargets()) == 0) {
        $self->debug("Forcing only local storing as no glpi server is configured and glpi_protocol is set");
        $self->{only_local_store} = 1;
    }

    # Handles request status
    $self->{status} = {};

    # Register events callback to support communication with our forked processes
    if (ref($self->{server}->{agent}) =~ /Daemon/) {
        $self->{server}->{agent}->register_events_cb($self);
    }
}

sub events_cb {
    my ($self, $event) = @_;

    unless (defined($event)) {
        # On no event, just check reqid timeouts
        return unless defined($self->{reqtimeout});
        my $count = scalar(@{$self->{reqtimeout}});
        while ($count--) {
            my $answer = $self->{reqtimeout}->[0];
            last unless time > $answer->{timeout};
            delete $self->{answer}->{$answer->{id}};
            if ($count) {
                shift @{$self->{reqtimeout}};
            } else {
                delete $self->{reqtimeout};
            }
        }
        return;
    }

    my ($name, $reqid, $dump) = $event =~ /^PROXYREQ,([^,]*),([^,]*),(.*)$/ms
        or return 0;

    # Plugin can be Proxy or SecondaryProxy, so we need to avoid events we don't own
    return 0 unless $name eq $self->name();

    if ($dump =~ /^\{/) {
        my $answer = GLPI::Agent::Protocol::Answer->new(
            message => $dump,
        );
        $self->{answer}->{$reqid} = $answer;
        # Add a timeout so the request memory could be freed even if the client won't ask for
        push @{$self->{reqtimeout}}, {
            timeout => time + 3600,
            id      => $reqid,
        };
    } elsif ($dump =~ /^\d+$/) {
        # Handle last 30 proxyreq timing to optimize expiration returned to proxy clients
        my $timing = int($dump);
        if (!$self->{_proxyreq_expiration} || $self->{_proxyreq_expiration} < $timing) {
            $self->{_proxyreq_expiration} = $timing;
        }
        push @{$self->{_proxyreq_timing}}, $timing;
        if (@{$self->{_proxyreq_timing}} > 30) {
            my $oldtiming = shift @{$self->{_proxyreq_timing}};
            # Found the higher timing
            if ($oldtiming == $self->{_proxyreq_expiration} && $oldtiming != $timing) {
                my $max = 0;
                map { $max = $_ if $_ > $max } @{$self->{_proxyreq_timing}};
                $self->{_proxyreq_expiration} = $max;
            }
        }
    } elsif ($dump eq "DELETE") {
        delete $self->{answer}->{$reqid};
        my @reqtimeouts = grep { $_->{id} ne $reqid } @{$self->{reqtimeout}};
        if (@reqtimeouts) {
            $self->{reqtimeout} = \@reqtimeouts;
        } else {
            delete $self->{reqtimeout};
        }
    }

    # Return true as we handled the event
    return 1;
}

sub handle {
    my ($self, $client, $request, $clientIp) = @_;

    my $agent = $self->{server}->{agent};

    # Set requestid from header if it matches the spec
    $requestid = $request->header('GLPI-Request-ID');
    undef $requestid unless defined($requestid) && $requestid =~ /^[0-9A-F]{8}$/;
    $self->{requestid} = $requestid;

    if ($self->{request} eq 'apiversion') {
        my $response = HTTP::Response->new(
            200,
            'OK',
            HTTP::Headers->new( 'Content-Type' => 'text/plain' ),
            $VERSION
        );

        $client->send_response($response);

        return 200;
    }

    # check against max_proxy_threads
    my $current_requests = $agent->forked(name => $self->name());
    if ($current_requests >= $self->config('max_proxy_threads')) {
        return $self->proxy_error(429, 'Too Many Requests');
    }

    # From here, signal SSL client socket should not be shutdown in parent
    $client->no_ssl_shutdown(1) if ref($client) eq 'HTTP::Daemon::ClientConn::SSL';

    return 1 if $agent->fork(name => $self->name(), description => $self->name()." request");

    # Keep client if we need it for proxy_error
    $self->{client} = $client;

    my $retcode = $self->_handle_proxy_request($request, $clientIp);

    delete $self->{client};

    $self->debug("response status $retcode");

    $client->close();

    $agent->fork_exit();

    return $retcode;
}

sub _send {
    my ($self, $answer) = @_;

    return unless $self->{client} && defined($answer);

    my $retcode = $answer->http_code;

    my $response = HTTP::Response->new(
        $retcode,
        $answer->http_status,
        HTTP::Headers->new( 'Content-Type' => $answer->contentType ),
        $answer->getContent(),
    );

    $response->header( 'GLPI-Request-ID' => $self->{requestid} ) if $self->{requestid};

    $self->{client}->send_response($response);

    return $retcode;
}

sub _handle_proxy_request {
    my ($self, $request, $clientIp) = @_;

    my $client = $self->{client}
        or return;

    return unless $request && $clientIp;

    my $remoteid = $clientIp;
    my $agent = $self->{server}->{agent};

    # From here SSL client socket must be shutdown properly
    $client->no_ssl_shutdown(0) if ref($client) eq 'HTTP::Daemon::ClientConn::SSL';

    my $content_type = $request->header('Content-type');
    $self->debug2("$content_type type request from $remoteid") if $content_type;

    my $proxyid = $request->header('GLPI-Proxy-ID') // "";
    if ($proxyid) {
        # Check pass-through limit
        my @proxies= split(/,/, $proxyid);
        if (@proxies >= $self->config('max_pass_through')) {
            $self->info("Max pass-through reached for request from $clientIp");
            return $self->_send(
                GLPI::Agent::Protocol::Answer->new(
                    httpcode    => 403,
                    httpstatus  => "LIMITED-PROXY",
                    status      => "error",
                    info        => "max-proxy-pass-through-reached",
                )
            );
        } elsif (grep { $agent->{agentid} eq $_ } @proxies) {
            $self->error("Proxy loop detected for request from $clientIp");
            return $self->_send(
                GLPI::Agent::Protocol::Answer->new(
                    httpcode    => 404,
                    httpstatus  => "PROXY-LOOP-DETECTED",
                    status      => "error",
                    info        => "proxy-loop-detected",
                )
            );
        }
    }

    my $params = $request->uri()->query();

    my $agentid = $request->header('GLPI-Agent-ID') // "";
    $remoteid = "$agentid\@$clientIp" if $agentid;

    # Handle GET requests with parameters in URL or GLPI-Request-ID as header

    if ($self->{requestid} && $request->method() eq "GET") {
        $self->debug("Asked for $self->{requestid} request status from $remoteid");
        my $answer = $self->{answer}->{$self->{requestid}};
        if ($answer && $answer->agentid eq $agentid) {

            # Remove answer when it is the finally expected one
            unless ($answer->http_code() == 202) {
                delete $self->{answer}->{$self->{requestid}};
                $agent->forked_process_event("PROXYREQ,".$self->name().",$self->{requestid},DELETE");
                $self->debug("Forgetting $self->{requestid} request status as last one expected from $remoteid");
            }

            return $self->_send($answer);
        } else {
            $self->info("Unknown $self->{requestid} request status for $remoteid");
            return $self->proxy_error(404, 'Unknown status');
        }
    } elsif ($params) {
        if ($params =~ /action=getConfig/) {
            $self->debug("$params request from $clientIp, sending nothing to do");
            my $response = HTTP::Response->new(
                200,
                'OK',
                HTTP::Headers->new( 'Content-Type' => 'application/json' ),
                '{}'
            );

            $client->send_response($response);

            return 200;
        } else {
            $self->info("Unsupported $params request from $clientIp");
            return $self->proxy_error(403, 'Unsupported request');
        }
    }

    unless ($content_type) {
        $self->info("No mandatory Content-type header provided in $self->{request} request from $clientIp");
        return $self->proxy_error(403, 'Content-type not set');
    }

    my $content = $request->content();
    unless (defined($content) && length($content)) {
        $self->info("No Content found in $self->{request} request from $clientIp");
        return $self->proxy_error(403, 'No content');
    }

    unless ($agent->{config}) {
        $self->info("Server configuration is missing");
        return $self->proxy_error(500, 'Server configuration missing');
    }

    # Uncompress and fix content-type if needed
    if ($content_type =~ m|^application/x-compress|i) {
        $content = GLPI::Agent::HTTP::Client::uncompress({ logger => $self }, $content, $content_type);
        if (empty($content)) {
            $self->info("Failed to uncompress $content_type Content in $self->{request} request from $clientIp");
            return $self->proxy_error(403, "Unsupported Compressed Content");
        }
        if ($content =~ /^{/) {
            $content_type = "application/json" ;
        } elsif ($content =~ /^<\?xml/) {
            $content_type = "application/xml";
        } else {
            $content_type = "plain/text";
        }
    }

    # GLPI protocol based on JSON
    return $self->_handle_glpi_protocol_request($agentid, $proxyid, $remoteid, $content, $clientIp)
        if $content_type =~ m|^application/json$|i;

    # Fallback here to legacy passive proxy mode, only for XML inventory submission
    return $self->_handle_legacy_protocol_request($agentid, $remoteid, $content, $clientIp)
        if $content_type =~ m|^application/xml$|i;

    $self->info("Unsupported '$content_type' Content-type header provided in $self->{request} request from $clientIp");
    return $self->proxy_error(403, 'Unsupported Content-type');
}

sub _handle_glpi_protocol_request {
    my ($self, $agentid, $proxyid, $remoteid, $content, $clientIp) = @_;

    my $client = $self->{client}
        or return;

    my $agent = $self->{server}->{agent};
    my @servers = $self->config('only_local_store') ? () : grep { $_->isGlpiServer() } $agent->getTargets();
    my $message;

    # Try to handle any JSON as GLPI agent protocol message
    eval {
        $message = GLPI::Agent::Protocol::Message->new(
            message => $content,
        );
    };
    if ($EVAL_ERROR) {
        $self->debug("Not supported message: $EVAL_ERROR");
        return $self->proxy_error(403, "Unsupported JSON Content");
    }

    if (empty($message->get('deviceid'))) {
        $self->debug("Not supported content");
        return $self->proxy_error(403, "Unsupported JSON Content");
    }

    my $action = $message->action;
    $self->debug("$action proxy request from $clientIp, agentid is $agentid");

    my $local_store = $self->config('local_store');
    if ($local_store && ! -d $local_store) {
        $self->error("No local store to store $remoteid inventory");
        return $self->proxy_error(500, 'Proxy local store missing');
    } elsif (!$local_store && $self->config('only_local_store') && $action ne "contact") {
        $self->error("No local store set to store $remoteid inventory");
        return $self->proxy_error(500, 'Proxy local store not set');
    }

    if ($local_store && $action ne "contact") {
        my $file = $local_store;
        my $json = ($message->get("deviceid") || $agentid).".json";
        $file =~ s|/*$||;
        $file .= "/$json";
        $self->debug("Saving $json from $remoteid in $local_store");
        my $DATA;
        unless (open($DATA, '>', $file)) {
            $self->error("Can't store $json from $remoteid");
            return $self->proxy_error(500, "Proxy failed to store json");
        }
        binmode($DATA);
        print $DATA $content;
        close($DATA);
        unless (-s $file == length($content)) {
            $self->error("Failed to store $json from $remoteid");
            return $self->proxy_error(500, "Proxy storing failure");
        }
    }

    if ($self->config('only_local_store') || !@servers) {
        my $answer = GLPI::Agent::Protocol::Answer->new(
            status      => "ok",
        );
        if ($action eq "contact") {
            my $inventory = {};
            $inventory->{"no-category"} = $self->config("no_category") if $self->config("no_category");
            $answer->merge(
                message => "contact on only storing proxy agent",
                tasks   => {
                    inventory   => $inventory
                },
                disabled    => [
                    qw( netdiscovery netinventory esx collect deploy wakeonlan )
                ],
                expiration  => $self->config("prolog_freq"),
            );
        }
        return $self->_send($answer);
    }

    my $timer = time;

    # Find a free requestid
    while (!defined($self->{requestid}) || ($self->{answer} && $self->{answer}->{$self->{requestid}})) {
        $self->{requestid} = join('', map { sprintf("%02X", int(rand(256))) } 1..4);
    }
    my $requestid = $self->{requestid};

    # From here we must tell client the request has been accepted and then
    # try to send inventory to servers
    my $expiration = $self->{_proxyreq_expiration} // 10;
    my $answer = GLPI::Agent::Protocol::Answer->new(
        httpcode    => 202,
        httpstatus  => "ACCEPTED",
        status      => "pending",
        agentid     => $agentid,
        proxyids    => $proxyid,
        expiration  => $expiration."s",
    );
    $agent->forked_process_event("PROXYREQ,".$self->name().",$requestid,".$answer->dump());

    # Notify client with pending status
    $self->_send($answer);

    # Update proxyid with our agentid to permit proxy loop detection
    if ($agent->{agentid}) {
        $proxyid .= "," if $proxyid;
        $proxyid .= uuid_to_string($agent->{agentid});
    }

    # Prepare a client to foward request
    my $proxyclient = GLPI::Agent::HTTP::Client::GLPI->new(
        logger  => $self->{logger},
        config  => $agent->{config},
        agentid => $agentid,
        proxyid => $proxyid,
    );

    foreach my $target (@servers) {
        $self->debug("Submitting $action from $remoteid to ".$target->getName());
        my $sent = $proxyclient->send(
            url     => $target->getUrl(),
            pending => "pass",
            message => $message
        );
        unless ($sent) {
            $answer->error($target->id." forward failure");
            $answer->expiration($self->config("prolog_freq"));
            $self->error("Failed to submit $remoteid $action to ".$target->getName()." server");
            last;
        }
        # Update our prolog_freq from the server one
        if ($action eq "contact" && $sent->status eq 'ok' && $sent->expiration()) {
            $expiration = $sent->expiration();
            $self->debug("Setting prolog_freq to $expiration");
            $self->config("prolog_freq", $expiration);
        }
        $answer->set($sent->get);
        $self->info("$remoteid $action submitted to ".$target->getName());
    }

    # Only report timing on good requests
    if ($answer->status ne "error") {
        if ($answer->status eq "ok") {
            $answer->success;
            $agent->forked_process_event("PROXYREQ,".$self->name().",$requestid,".(int(time-$timer)+1));
        } elsif ($answer->status eq "pending") {
            # Case server is another proxy returning a pending status
            $agent->forked_process_event("PROXYREQ,".$self->name().",$requestid,".(int(time-$timer)+$answer->expiration));
        }
    }
    $agent->forked_process_event("PROXYREQ,".$self->name().",$requestid,".$answer->dump());

    return $answer->http_code;
}

sub _handle_legacy_protocol_request {
    my ($self, $agentid, $remoteid, $content, $clientIp) = @_;

    my $client = $self->{client}
        or return;

    my $agent = $self->{server}->{agent};

    my $deviceid;
    if ($content !~ m|^<\?xml|ms) {
        $self->info("Unsupported content in $self->{request} request from $clientIp");
        $self->debug("Content from $clientIp was starting with '".(substr($content,0,40))."'");
        return $self->proxy_error(403, 'Unsupported content');
    }

    # Check if it's a PROLOG request
    my $xml = GLPI::Agent::XML->new(string => $content);
    unless ($xml->has_xml()) {
        $self->info("Unsupported content in $self->{request} request from $clientIp");
        $self->debug("Content from $clientIp was starting with '".(substr($content,0,40))."'");
        return $self->proxy_error(403, 'Unsupported xml content');
    }

    my $dump = $xml->dump_as_hash();
    my $query = exists($dump->{REQUEST}->{QUERY}) ? $dump->{REQUEST}->{QUERY} : '';

    unless ($query && $query =~ /^PROLOG|INVENTORY|NETDISCOVERY|SNMPQUERY$/) {
        $self->info("Not supported ".($query||"unknown")." query from $remoteid");
        my ($sample) = $content =~ /^(.{1,80})/ms;
        if ($sample) {
            $sample =~ s/\n\s*//gs;
            $sample = getSanitizedString($sample);
            $self->debug("Not supported XML looking like: $sample")
                if $sample;
        }
        return $self->proxy_error(403, 'Unsupported query');
    }

    $deviceid = exists($dump->{REQUEST}->{DEVICEID}) ? $dump->{REQUEST}->{DEVICEID} : '';

    unless ($deviceid) {
        $self->info("Not supported $query query from $remoteid");
        return $self->proxy_error(403, "$query query without deviceid");
    }

    $remoteid = $deviceid . '@' . $clientIp;
    $self->info("$query query from $remoteid");

    if ($query eq 'PROLOG' && $self->config('only_local_store')) {

        $self->debug2("PROLOG request from $remoteid");

        my $response = HTTP::Response->new(200, 'OK');

        if ($self->{glpi_protocol}) {
            my $answer = GLPI::Agent::Protocol::Answer->new(
                status      => "ok",
            );
            my $inventory = {};
            $inventory->{"no-category"} = $self->config("no_category") if $self->config("no_category");
            $answer->merge(
                message => "contact on only storing proxy agent",
                tasks   => {
                    inventory   => $inventory
                },
                disabled    => [
                    qw( netdiscovery netinventory esx collect deploy wakeonlan )
                ],
                expiration  => $self->config("prolog_freq"),
            );
            $response->header( 'Content-Type' => 'application/json' );
            $response->content($answer->getContent());
        } else {
            my $xml = GLPI::Agent::XML->new();
            my $data = {
                REPLY => {
                    RESPONSE    => 'SEND',
                    PROLOG_FREQ => $self->config("prolog_freq")
                }
            };
            $response->header( 'Content-Type' => 'application/xml' );
            $response->content($xml->write($data));
        }

        $client->send_response($response);

        return 200;
    }

    $self->debug("proxy request for $remoteid");

    my $response = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new( 'Content-Type' => 'application/xml' ),
        "<?xml version='1.0' encoding='UTF-8'?>\n<REPLY><RESPONSE>SEND</RESPONSE></REPLY>\n"
    );

    my @servers;
    if ($self->config('only_local_store')) {
        unless ($self->config('local_store') && -d $self->config('local_store')) {
            $self->error("Can't store content from $clientIp $self->{request} request without storage folder");
            return $self->proxy_error(500, 'No local storage for inventory');
        }
    } else {
        @servers = grep { $_->isType('server') } $agent->getTargets();
    }

    if ($self->config('local_store') && -d $self->config('local_store')) {
        my $xmlfile = $self->config('local_store');
        $xmlfile =~ s|/*$||;
        $xmlfile .= "/$deviceid.xml";
        $self->debug("Saving inventory in $xmlfile");
        my $XML;
        if (!open($XML, '>', $xmlfile)) {
            $self->error("Can't store content from $clientIp $self->{request} request");
            return $self->proxy_error(500, 'Proxy cannot store content');
        }
        binmode($XML);
        print $XML $content;
        close($XML);
        if (-s $xmlfile != length($content)) {
            $self->error("Can't store content from $clientIp $self->{request} request");
            return $self->proxy_error(500, 'Proxy content store failure');
        }
        if ($self->config('only_local_store')) {
            $client->send_response($response);
            return 200;
        }
    }

    # Client will only obtain PROLOG response from the first server target

    if (@servers) {
        my $proxyclient = GLPI::Agent::HTTP::Client::OCS->new(
            logger  => $self->{logger},
            config  => $agent->{config},
            agentid => $agentid,
        );

        my $message = GLPI::Agent::HTTP::Server::Proxy::Message->new(
            content  => $content,
        );

        my $count = 0;
        foreach my $target (@servers) {
            $self->debug("Submitting inventory from $remoteid to ".$target->getName());
            my $sent = $proxyclient->send(
                url     => $target->getUrl(),
                message => $message
            );
            unless ($sent) {
                $self->error("Failed to submit $remoteid inventory to ".$target->getName()." server");
                return $self->proxy_error(500, 'Inventory not sent to '.$target->id());
            }
            $self->info("Inventory from $remoteid submitted to ".$target->getName());
            if ($query eq 'PROLOG' && ++$count == 1) {
                # On PROLOG query, we always use the first server answer
                my $content = $sent->getContent();
                if (ref($sent) =~ /^GLPI::Agent::Protocol::/) {
                    $response->content($content);
                    $response->header('Content-Type' => 'application/json');
                } else {
                    my $reply = GLPI::Agent::HTTP::Server::Proxy::Reply->new(
                        content  => $content,
                    );
                    $response->content($reply->getContent());
                }
            }
        }
    }

    $client->send_response($response);

    return $response->code();
}

sub proxy_error {
    my ($self, $rc, $error) = @_;

    $self->{client}->send_status_line($rc, $error)
        if $self->{client};

    return $rc;
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Server::Proxy - An embedded HTTP server plugin
providing a proxy for agents not able to contact the server

=head1 DESCRIPTION

This is a server plugin to transmit inventory toward a server.

It listens on port 62354 by default.

The following default requests are accepted:

=over

=item /proxy/glpi

=item /proxy/apiversion

=back

=head1 CONFIGURATION

=over

=item disabled         C<yes> by default

=item url_path         C</proxy> by default

=item port             C<0> by default to use default one

=item prolog_freq      C<24> by default, this is the delay agents will finally
                       recontact the proxy

=item local_store      empty by default, this is the folder where to store inventories

=item only_local_store C<no> by default, set it to C<yes> to not submit inventories
                       to server.

=item maxrate          C<30> by default

=item maxrate_period   C<3600> (in seconds) by default.

=back

Defaults can be overrided in C<proxy-server-plugin.cfg> file or better in the
C<proxy-server-plugin.local> if included from C<proxy-server-plugin.cfg>.
