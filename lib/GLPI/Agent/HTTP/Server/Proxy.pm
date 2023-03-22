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
use GLPI::Agent::HTTP::Client::OCS;
use GLPI::Agent::HTTP::Client::GLPI;

use GLPI::Agent::Protocol::Message;
use GLPI::Agent::Protocol::Answer;

our $VERSION = "2.2";

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
    };
}

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

    my ($reqid, $dump) = $event =~ /^PROXYREQ,([^,]*),(.*)$/ms
        or return 0;

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

    # rate limit by ip to avoid abuse
    if ($self->rate_limited($clientIp)) {
        return $self->proxy_error(429, 'Too Many Requests');
    }

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

    $self->{client} = $client;

    my $retcode = $self->_handle_proxy_request($request, $clientIp);

    # In the case we run in a fork, just close the socket and quit
    if ($agent->forked()) {
        $self->debug("response status $retcode");
        $client->close();
        $agent->fork_exit(logger => $self, name => $self->name());
    }

    delete $self->{client};

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

    # /proxy/glpi request

    # From here we should fork and return
    my $agent = $self->{server}->{agent};
    unless ($agent->forked()) {
        # check against max_proxy_threads
        my $current_requests = $agent->forked(name => $self->name());

        if ($current_requests >= $self->config('max_proxy_threads')) {
            return $self->proxy_error(429, 'Too Many Requests');
        }

        return 1 if $agent->fork(name => $self->name(), description => $self->name()." request");
    }

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

    my ($url, $params) = split(/[?]/, $request->uri());

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
                $agent->forked_process_event("PROXYREQ,$self->{requestid},DELETE");
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

    my @servers = ();
    my $serverconfig = $agent->{config};
    unless ($serverconfig) {
        $self->info("Server configuration is missing");
        return $self->proxy_error(500, 'Server configuration missing');
    }

    # Uncompress if needed
    if ($content_type =~ m|^application/x-compress(-zlib)?$|i && $content =~ /(\x78\x9C.*)/s) {
        $content = Compress::Zlib::uncompress($content);
    } elsif ($content_type =~ m|^application/x-compress-gzip$|i) {
        my $in = File::Temp->new(SUFFIX => '.proxy');
        print $in $content;
        close($in);

        $content = getAllLines(
            command => 'gzip -dc ' . $in->filename(),
            logger  => $self->{logger}
        );

        unless (defined($content)) {
            $self->info("Can't uncompress $content_type Content-type in $self->{request} request from $clientIp");
            return $self->proxy_error(403, "Unsupported $content_type Content-type");
        }
    }

    # Fix content-type if it has been uncompressed
    if ($content_type =~ m|^application/x-compress|) {
        $content_type = "application/json" if $content =~ /^{/;
        $content_type = "application/xml" if $content =~ /^<\?xml/;
    }

    @servers = grep { $_->isGlpiServer() } $agent->getTargets()
        unless $self->config('only_local_store');

    # GLPI protocol based on JSON involves the usage of dedicated HTTP headers
    # GLPI-Agent-ID is mandatory in that case
    if ($self->config('glpi_protocol') && $agentid && is_uuid_string($agentid) && (@servers || $self->config('only_local_store'))) {

        my $message;
        if ($content_type !~ m|^application/json$|i) {
            # Only not json request expected here is a contact request
            my $xml = GLPI::Agent::XML->new(string => $content)->dump_as_hash();
            unless ($xml) {
                $self->debug("Not supported message: $EVAL_ERROR");
                return $self->proxy_error(403, "Unsupported Content");
            }
            unless ($xml && $xml->{REQUEST} && $xml->{REQUEST}->{QUERY} && $xml->{REQUEST}->{QUERY} eq "PROLOG") {
                $self->debug("Not supported message: Not a legacy CONTACT");
                return $self->proxy_error(403, "Not a legacy CONTACT");
            }
            unless ($xml->{REQUEST}->{DEVICEID}) {
                $self->debug("Not supported message: No deviceid in CONTACT");
                return $self->proxy_error(403, "No deviceid in CONTACT");
            }
            $self->debug("Got legacy PROLOG request from $remoteid");
            # By default, tell agent to request contact asap with new protocol
            my $answer = GLPI::Agent::Protocol::Answer->new(
                httpcode    => 202,
                httpstatus  => "ACCEPTED",
                status      => "pending",
                agentid     => $agentid,
                proxyids    => $proxyid,
                expiration  => 0,
            );
            # But emulate a server answer when needed
            if ($self->config('only_local_store')) {
                $self->debug("Answering as a GLPI server would do to $remoteid");
                $answer->success();
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
            } else {
                $self->debug("Answering to $remoteid client to immediatly use GLPI protocol");
            }
            return $self->_send($answer);
        }

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
            $file =~ s|/*$||;
            $file .= "/$agentid.data";
            $self->debug("Saving datas from $remoteid in $file");
            my $DATA;
            unless (open($DATA, '>', $file)) {
                $self->error("Can't store datas from $remoteid");
                return $self->proxy_error(500, "Proxy failed to store datas");
            }
            binmode($DATA);
            print $DATA $content;
            close($DATA);
            unless (-s $file == length($content)) {
                $self->error("Failed to store datas from $remoteid");
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
        $requestid = $self->{requestid};

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
        $agent->forked_process_event("PROXYREQ,$requestid,".$answer->dump());

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
            config  => $serverconfig,
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
                $agent->forked_process_event("PROXYREQ,$requestid,".(int(time-$timer)+1));
            } elsif ($answer->status eq "pending") {
                # Case server is another proxy returning a pending status
                $agent->forked_process_event("PROXYREQ,$requestid,".(int(time-$timer)+$answer->expiration));
            }
        }
        $agent->forked_process_event("PROXYREQ,$requestid,".$answer->dump());

        return $answer->http_code;
    }

    # Fallback here to legacy passive proxy mode, only for XML inventory submission

    if ($content_type !~ m|^application/xml$|i) {
        $self->info("Unsupported '$content_type' Content-type header provided in $self->{request} request from $clientIp");
        return $self->proxy_error(403, 'Unsupported Content-type');
    }

    unless (defined($content) && length($content)) {
        $self->info("No Content found in $self->{request} request from $clientIp");
        return $self->proxy_error(403, 'No content');
    }

    my $deviceid;
    if ($content =~ m|^<\?xml|ms) {
        # Check if it's a PROLOG request
        my $xml = GLPI::Agent::XML->new(string => $content);
        unless ($xml->has_xml()) {
            $self->info("Unsupported content in $self->{request} request from $clientIp");
            $self->debug("Content from $clientIp was starting with '".(substr($content,0,40))."'");
            return $self->proxy_error(403, 'Unsupported xml content');
        }

        my $dump = $xml->dump_as_hash();
        my $query = exists($dump->{REQUEST}->{QUERY}) ? $dump->{REQUEST}->{QUERY} : '';

        unless ($query && $query =~ /^PROLOG|INVENTORY$/) {
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

        if ($query eq 'PROLOG') {

            $self->debug2("PROLOG request from $remoteid");

            my $xml = GLPI::Agent::XML->new();
            my $data = {
                REPLY => {
                    RESPONSE    => 'SEND',
                    PROLOG_FREQ => $self->config("prolog_freq")
                }
            };

            my $response = HTTP::Response->new(
                200,
                'OK',
                HTTP::Headers->new( 'Content-Type' => 'application/xml' ),
                $xml->write($data)
            );

            $client->send_response($response);

            return 200;
        }
    } else {
        $self->info("Unsupported content in $self->{request} request from $clientIp");
        $self->debug("Content from $clientIp was starting with '".(substr($content,0,40))."'");
        return $self->proxy_error(403, 'Unsupported content');
    }

    $self->debug("proxy request for $remoteid");

    my $response = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new( 'Content-Type' => 'application/xml' ),
        "<?xml version='1.0' encoding='UTF-8'?>\n<REPLY></REPLY>\n"
    );

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

    if (@servers) {
        my $proxyclient = GLPI::Agent::HTTP::Client::OCS->new(
            logger  => $self->{logger},
            config  => $serverconfig,
        );

        my $message = GLPI::Agent::HTTP::Server::Proxy::Message->new(
            content  => $content,
        );

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
        }
    }

    $client->send_response($response);

    return $response->code();
}

sub proxy_error {
    my ($self, $rc, $error) = @_;

    return $rc unless $self->{client};

    my $header = HTTP::Headers->new('Content-Type' => 'text/plain; charset=utf-8');
    my $response = HTTP::Response->new($rc, $error, $header, $error);

    $self->{client}->send_response($response);

    return $rc;
}

## no critic (ProhibitMultiplePackages)
package
    GLPI::Agent::HTTP::Server::Proxy::Message;

sub new {
    my ($class, %params) = @_;

    my $self = {
        content => $params{content},
    };
    bless $self, $class;
}

sub getContent {
    my ($self) = @_;

    return $self->{content};
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
