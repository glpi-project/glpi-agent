package GLPI::Agent::HTTP::Server::Inventory;

use strict;
use warnings;

use English qw(-no_match_vars);

use base "GLPI::Agent::HTTP::Server::Plugin";

use GLPI::Agent::Tools;
use GLPI::Agent::Task::Inventory;
use GLPI::Agent::Target::Listener;

our $VERSION = "1.1";

sub urlMatch {
    my ($self, $path) = @_;
    # By default, re_path_match => qr{^/inventory/(session|get|apiversion)$}
    return 0 unless $path =~ $self->{re_path_match};
    $self->{request} = $1;
    return 1;
}

sub log_prefix {
    return "[inventory server plugin] ";
}

sub config_file {
    return "inventory-server-plugin.cfg";
}

sub defaults {
    return {
        disabled            => "yes",
        url_path            => "/inventory",
        port                => 0,
        token               => undef,
        session_timeout     => 60,
        no_compress         => "no",
        # Supported by class GLPI::Agent::HTTP::Server::Plugin
        maxrate             => 30,
        maxrate_period      => 3600,
    };
}

sub init {
    my ($self) = @_;

    $self->SUPER::init(@_);

    # Don't do more initialization if disabled
    return if $self->disabled();

    # Check secret is set if plugin is enabled
    unless ($self->config('token')) {
        $self->error("Plugin enabled without token in configuration");
        $self->disable("Plugin disabled on wrong configuration");
        return;
    }

    $self->{request}  = 'none';

    my $defaults = $self->defaults();
    my $url_path = $self->config('url_path');
    $self->debug("Using $url_path as base url matching")
        if ($url_path ne $defaults->{url_path});
    $self->{re_path_match} = qr{^$url_path/(session|get|apiversion)$};

    # Always uses a dedicated Listener target for this plugin. It will give access
    # to stored sessions
    $self->{target} = GLPI::Agent::Target::Listener->new(
        logger     => $self->{logger},
        basevardir => $self->{server}->{agent}->{config}->{vardir},
    ) unless $self->{target};

    # Normalize no_compress
    $self->{no_compress} = $self->config('no_compress') !~ /^0|no$/i ? 1 : 0;
}

sub handle {
    my ($self, $client, $request, $clientIp) = @_;

    my $logger = $self->{logger};
    my $target = $self->{target};

    # rate limit by ip to avoid abuse
    if ($self->rate_limited($clientIp)) {
        $client->send_error(429); # Too Many Requests
        return 429;
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

    my $id = $request->header('X-Request-ID');

    unless ($id) {
        $self->info("No mandatory X-Request-ID header provided in $self->{request} request from $clientIp");
        $client->send_error(403, 'No session available');
        return 403;
    }

    my $remoteid = "{$id}\@[$clientIp]";

    my $session = $target->session(
        remoteid    => $remoteid,
        timeout     => $self->config('session_timeout'),
    );

    unless ($session) {
        $self->info("No session available for $remoteid");
        $client->send_error(403, 'No session available');
        return 403;
    }

    $self->debug("Session sid for $remoteid: ".$session->sid());

    if ($self->{request} eq 'session') {

        my $nonce = $session->nonce();

        unless ($nonce) {
            $self->info("Session setup failure for $remoteid");
            $client->send_error(500, 'Session failure');
            return 500;
        }

        # Returned content is not useful but it should not be empty to support keep-alive
        # This is a LWP::UserAgent limitation
        my $response = HTTP::Response->new(
            200,
            'OK',
            HTTP::Headers->new( 'X-Auth-Nonce' => $nonce, 'Content-Type' => 'Plain/Text' ),
            "waiting inventory request..."
        );

        $client->send_response($response);

        return 200;
    }

    my $authorization = $session->authorized(
        token   => $self->config('token'),
        payload => $request->header('X-Auth-Payload') || ''
    );

    # Still cleanup the session
    $target->clean_session($session);

    unless ($authorization) {
        $self->info("unauthorized remote inventory request for $remoteid");
        $client->send_error(403);
        return 403;
    }

    $self->debug("remote inventory request for $remoteid");

    my $agent = $self->{server}->{agent};

    my $task = GLPI::Agent::Task::Inventory->new(
        logger   => $logger,
        target   => $target,
        deviceid => $agent->{deviceid},
        datadir  => $agent->{datadir},
        config   => $agent->{config},
    );

    my $done;
    {
        local $SIG{CHLD} = sub {};
        $done = $task->run();
    }

    unless ($done) {
        $self->error("Failed to run inventory");
        $client->send_error(500, "Inventory failure");
        return 500;
    }

    my $data = $target->inventory_xml();
    my $content_type = 'application/xml';
    my @accept = split(/, */,$request->header('accept') || '');

    # check compression mode
    if (!$self->{no_compress} && Compress::Zlib->require() && grep { m|application/x-compress-zlib| } @accept) {
        # RFC 1950
        $content_type = 'application/x-compress-zlib';
        $self->debug('Using Compress::Zlib for compression');
        $data = Compress::Zlib::compress($data);
    } elsif (!$self->{no_compress} && canRun('gzip') && grep { m|application/x-compress-gzip| } @accept) {
        # RFC 1952
        $content_type = 'application/x-compress-gzip';
        $self->debug('Using gzip for compression');

        File::Temp->require();
        my $fd = File::Temp->new();
        print $fd $data;
        close $fd;

        $data = getAllLines(
            command => 'gzip -c ' . $fd->filename(),
            logger  => $self->{logger}
        );
    }

    my $response = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new( 'Content-Type' => $content_type ),
        $data
    );

    $client->send_response($response);

    $self->info("Inventory returned to $remoteid");

    return 200;
}

sub timer_event {
    my ($self) = @_;
    return $self->{target} && $self->{target}->keep_sessions();
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Server::Inventory - An embedded HTTP server plugin
providing remote inventory

=head1 DESCRIPTION

This is a server plugin to listen for inventory requests.

It listens on port 62354 by default and can answer with a full inventory XML if
authorized.

The following default requests are accepted:

=over

=item /inventory/session

=item /inventory/get

=item /inventory/apiversion

=back

Authentication is firstly based on connection source address: trusted requests
can access the API. But a shared secret must be known to use the API.

A client must request a session before being able to request an inventory.

A 'X-Request-ID' header must be provided for a session creation:

The session permits to control access with a shared secret or token so an
inventory can only be provided if the returned payload matches the expected one.

The server answers with a nonce set in the 'X-Auth-Nonce' header.

For the /get call, the client must still provide a 'X-Request-ID' header but it
also must provide a 'X-Auth-Payload' one computed from 'X-Auth-Nonce' provided
value and the shared secret.

=head1 CONFIGURATION

=over

=item disabled         C<yes> by default

=item url_path         C</inventory> by default

=item port             C<0> by default to use default one

=item token            not defined by default. /get API is disabled untill one is set

=item session_timeout  C<60> (in seconds) by default.

=item maxrate          C<30> by default

=item maxrate_period   C<3600> (in seconds) by default.

=item no_compress      C<no> by default to keep XML compression possible.

=back

Defaults can be overrided in C<inventory-server-plugin.cfg> file or better in the
C<inventory-server-plugin.local> if included from C<inventory-server-plugin.cfg>.
