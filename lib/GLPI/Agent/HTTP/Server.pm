package GLPI::Agent::HTTP::Server;

use strict;
use warnings;

use UNIVERSAL::require;
use English qw(-no_match_vars);
use File::Basename;
use HTTP::Daemon;
use IO::Handle;
use Net::IP;
use Text::Template;
use File::Glob;
use URI;
use Socket;
use URI::Escape;

use GLPI::Agent::Version;
use GLPI::Agent::Logger;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;

# Expire trusted ip/ranges cache after a minute
use constant TRUSTED_CACHE_TIMEOUT => 60;

# Limit maximum requests number handled in a keep-alive connection
use constant MaxKeepAlive => 8;

my $log_prefix = "[http server] ";

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger    => $params{logger} ||
                     GLPI::Agent::Logger->new(),
        agent     => $params{agent},
        htmldir   => $params{htmldir},
        ip        => $params{ip},
        port      => $params{port} || 62354,
        listeners => {},
    };
    bless $self, $class;

    $self->_handleTrustedAddressesCache($params{trust});

    # Load any Server sub-module as plugin
    my @plugins = ();
    my ($sub_modules_path) = $INC{module2file(__PACKAGE__)} =~ /(.*)\.pm/;
    foreach my $file (File::Glob::bsd_glob("$sub_modules_path/*.pm")) {
        if ($OSNAME eq 'MSWin32') {
            $file =~ s{\\}{/}g;
            $sub_modules_path =~ s{\\}{/}g;
        }

        my ($name) = $file =~ m{$sub_modules_path/(\S+)\.pm$};
        next unless $name;

        # Don't load Plugin base class
        next if $name eq "Plugin";

        $self->{logger}->debug($log_prefix . "Trying to load $name Server plugin");

        my $module = __PACKAGE__ . "::" . $name;
        $module->require();
        if ($EVAL_ERROR) {
            $self->{logger}->debug($log_prefix . "Failed to load $name Server plugin: $EVAL_ERROR");
            next;
        }

        my $plugin = $module->new(server => $self)
            or next;

        $plugin->init();
        if ($plugin->disabled()) {
            $self->{logger}->debug($log_prefix . "HTTPD $name Server plugin loaded but disabled");
        } else {
            $self->{logger}->info($log_prefix . "HTTPD $name Server plugin loaded");
            push @plugins, $plugin;
        }
    }

    # Sort and store loaded plugins
    @plugins = sort { $b->priority() <=> $a->priority() } @plugins
        if @plugins > 1;
    $self->{_plugins} = \@plugins;

    return $self;
}

sub _handleTrustedAddressesCache {
    my ($self, $trust) = @_;

    # Initialize trusted cache or check expiration
    if ($trust) {
        $self->{trusted_cache_trust} = $trust;
    } else {
        # No cache needed unless it has been initialized with some trusted ip or range
        # But log untrusted during re-init
        return $self->_log_untrusted(delete $self->{trust})
            unless $self->{trusted_cache_trust};
        # Check cache expirarion
        return unless time > $self->{trusted_cache_expiration};
        $trust = $self->{trusted_cache_trust};
    }

    # Always reset trust adresses
    my $delete = delete $self->{trust} // {};

    # compute addresses allowed for push requests
    foreach my $target ($self->{agent}->getTargets()) {
        next unless $target->isType('server');
        my $url  = $target->getUrl();
        my $host = URI->new($url)->host();
        # Don't resolv server address if still found
        next if $self->{trust}->{$host};
        my @addresses = compile($host, $self->{logger})
            or next;
        $self->{trust}->{$host} = \@addresses;
        $self->{logger}->debug("Trusted target ip: ".join(", ",map { $_->print() } @addresses));
        # Forget previous definition
        delete $delete->{$host};
    }

    # Add addresses and ranges defined by httpd-trust option
    foreach my $string (@{$trust}) {
        # Don't resolv server address if still found
        next if $self->{trust}->{$string};
        my @addresses = compile($string, $self->{logger})
            or next;
        $self->{trust}->{$string} = \@addresses;
        $self->{logger}->debug("Trusted client ip/range: ".join(", ",map { $_->print() } @addresses));
        # Forget previous definition
        delete $delete->{$string};
    }

    # Log lost trust
    $self->_log_untrusted($delete);

    # Define cache expiration
    $self->{trusted_cache_expiration} = time + TRUSTED_CACHE_TIMEOUT;
}

sub _log_untrusted {
    my ($self, $delete) = shift;

    return unless ref($delete) eq 'HASH';

    # Log lost trust
    foreach my $string (keys(%{$delete})) {
        $self->{logger}->debug("'$string' client no more trusted");
    }
}

sub _handle {
    my ($self, $client, $request, $clientIp, $maxKeepAlive) = @_;

    my $logger = $self->{logger};

    if (!$request) {
        $client->close();
        return;
    }

    my $path = $request->uri()->path();
    my $method = $request->method();
    $logger->debug($log_prefix . "$method request $path from client $clientIp");

    my $keepalive = ($request->header('connection') // '') =~ /keep-alive/i;
    my $status = 400;
    my $error_400 = $log_prefix . "invalid request type: $method";

    SWITCH: {
        # root request
        if ($path eq '/') {
            last SWITCH if $method ne 'GET';
            $status = $self->_handle_root($client, $request, $clientIp);
            last SWITCH;
        }

        # static content request
        if ($path =~ m{^/(logo\.png|site\.css|favicon\.ico)$}) {
            my $file = $1;
            last SWITCH if $method ne 'GET';
            $client->send_file_response("$self->{htmldir}/$file");
            $status = 200;
            last SWITCH;
        }

        # deploy request
        if ($path =~ m{^/deploy/getFile/./../([\w\d/-]+)$}) {
            last SWITCH if $method ne 'GET';
            $status = $self->_handle_deploy($client, $request, $clientIp, $1);
            last SWITCH;
        }

        # plugins request
        foreach my $plugin (@{$self->{_plugins}}) {
            next if $plugin->disabled();
            if ($plugin->urlMatch($path)) {
                undef $error_400;
                last SWITCH unless $plugin->supported_method($method);
                $status = $plugin->handle($client, $request, $clientIp);
                last SWITCH if $status;
            }
        }

        # now request
        if ($path =~ m{^/now(?:/\S*)?$}) {
            last SWITCH if $method ne 'GET';
            $status = $self->_handle_now($client, $request, $clientIp);
            last SWITCH;
        }

        # status request
        if ($path eq '/status') {
            last SWITCH if $method ne 'GET';
            $status = $self->_handle_status($client, $request, $clientIp);
            last SWITCH;
        }

        $error_400 = $log_prefix . "unknown path: $path";
    }

    if ($status == 400) {
        $logger->error($error_400) if $error_400;
        $client->send_error(400)
    }

    $logger->debug($log_prefix . "response status $status") unless $status == 1;

    # Handle keepalive for success and authentication required status
    if ((any { $status == $_ } (200, 401)) && $keepalive && --$maxKeepAlive) {
        # Looking for another request
        $request = $client->get_request();
        $self->_handle($client, $request, $clientIp, $maxKeepAlive) if $request;
    }

    $client->close();
}

sub _handle_plugins {
    my ($self, $client, $request, $clientIp, $plugins, $maxKeepAlive) = @_;

    my $logger = $self->{logger};

    if (!$request) {
        $client->close();
        return;
    }

    my $path = $request->uri()->path();
    my $method = $request->method();
    my $keepalive = ($request->header('connection') // '') =~ /keep-alive/i;
    $logger->debug($log_prefix . "$method request $path from client $clientIp via plugin");
    my $status = 400;
    my $match  = 0;

    foreach my $plugin (@{$plugins}) {
        next if $plugin->disabled();
        if ($plugin->urlMatch($path)) {
            $match = 1;
            last unless ($plugin->supported_method($method));
            $status = $plugin->handle($client, $request, $clientIp);
            $self->{_timer_event} = time+10
                if ($self->{_timer_event} > time+10);
            last if $status;
        }
    }

    if ($status == 400) {
        $logger->error($log_prefix . "unknown path: $path") unless $match;
        $client->send_error(400);
        $status = 400;
    }

    # Don't log status if we forked
    $logger->debug($log_prefix . "response status $status") unless $status == 1;

    # Handle keepalive for success and authentication required status
    if ((any { $status == $_ } (200, 401)) && $keepalive && --$maxKeepAlive) {
        # Looking for another request
        $request = $client->get_request();
        $self->_handle_plugins($client, $request, $clientIp, $plugins, $maxKeepAlive) if $request;
    }

    $client->close();
}

sub _handle_root {
    my ($self, $client, $request, $clientIp) = @_;

    my $logger = $self->{logger};

    my $template = Text::Template->new(
        TYPE => 'FILE', SOURCE => "$self->{htmldir}/index.tpl"
    );
    if (!$template) {
        $logger->error(
            $log_prefix . "Template access failed: $Text::Template::ERROR"
        );

        my $response = HTTP::Response->new(
            500,
            'KO',
            HTTP::Headers->new('Content-Type' => 'text/html'),
            "No template"
        );

        $client->send_response($response);
        return 500;
    }

    my @server_targets =
        map { { name => $_->getUrl(), date => $_->getFormatedNextRunDate() } }
        grep { $_->isType('server') }
        $self->{agent}->getTargets();

    my @local_targets =
        map { { name => $_->getPath(), date => $_->getFormatedNextRunDate() } }
        grep { $_->isType('local') }
        $self->{agent}->getTargets();

    my @httpd_plugins = map { @{$_->{plugins}} } values(%{$self->{listeners}});
    push @httpd_plugins, @{$self->{_plugins}};
    my @listening_plugins =
        map { { port => $_->config('port') || $self->{port}, name => $_->name() } }
            grep { ! $_->disabled() }
                @httpd_plugins;

    my @sessions = ();
    if ($logger && $logger->debug_level() > 1) {
        GLPI::Agent::Target::Listener->require();
        if ($EVAL_ERROR) {
            $self->{logger}->debug($log_prefix . "Failed to load Listener target module: $EVAL_ERROR");
        } else {
            my $listener = GLPI::Agent::Target::Listener->new(
                logger     => $self->{logger},
                basevardir => $self->{agent}->{config}->{vardir},
            );
            my $sessions = $listener->sessions();
            foreach my $sid (sort { $a cmp $b } keys(%{$sessions})) {
                push @sessions, $sessions->{$sid}->info();
            }
        }
    }

    my $hash = {
        version        => $GLPI::Agent::Version::VERSION,
        trust          => $self->_isTrusted($clientIp),
        status         => $self->{agent}->getStatus(),
        httpd_plugins  => \@listening_plugins,
        server_targets => \@server_targets,
        local_targets  => \@local_targets,
        sessions       => \@sessions,
    };

    my $response = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new('Content-Type' => 'text/html'),
        $template->fill_in(HASH => $hash)
    );

    $client->send_response($response);
    return 200;
}

sub _handle_deploy {
    my ($self, $client, $request, $clientIp, $sha512) = @_;

    return unless $sha512 =~ /^(.)(.)(.{6})/;
    my $subFilePath = $1.'/'.$2.'/'.$3;

    my $logger = $self->{logger};

    Digest::SHA->require();
    if ($EVAL_ERROR) {
        $logger->error("Failed to load Digest::SHA: $EVAL_ERROR");
        # Return 501 (Not Implemented) to client with reason
        $client->send_error(501, 'Digest::SHA perl library is missing');
        return 501;
    }

    my $path;
    my $count = 0;
    LOOP: foreach my $target ($self->{agent}->getTargets()) {
        foreach (File::Glob::bsd_glob($target->{storage}->getDirectory() . "/deploy/fileparts/shared/*")) {
            next unless -f $_.'/'.$subFilePath;

            $count ++;

            my $sha = Digest::SHA->new('512');
            $sha->addfile($_.'/'.$subFilePath, 'b');
            next unless $sha->hexdigest eq $sha512;

            $path = $_.'/'.$subFilePath;
            last LOOP;
        }
    }
    if ($path) {
        $client->send_file_response($path);
        return 200;
    } else {
        if ($count) {
            $client->send_error(404);
        } else {
            # Report this agent as nothing to share
            $client->send_error(404, 'Nothing found');
        }
        return 404;
    }
}

sub _handle_now {
    my ($self, $client, $request, $clientIp) = @_;

    my $logger = $self->{logger};

    my ($code, $message) = qw( 200 OK );
    my $trace;

    my @targets;
    foreach my $target ($self->{agent}->getTargets()) {
        next unless $target->isType('server');
        my $url       = $target->getUrl();
        my $addresses = $self->{trust}->{$url};
        next unless isPartOf($clientIp, $addresses, $logger);
        $trace = "rescheduling next contact for target $url right now";
        push @targets, $target;
        last;
    }

    push @targets, $self->{agent}->getTargets()
        if !@targets && $self->_isTrusted($clientIp);

    if (@targets) {
        my $query = uri_unescape($request->uri()->query());
        if ($query) {
            my %event = map { /^([^=]+)=(.*)$/ } grep { /[^=]=/ } split('&', $query);
            foreach my $target (@targets) {
                if (my $event = $target->addEvent(\%event)) {
                    $logger->debug($log_prefix."$event->{name} triggering event on ".$target->id());
                } else {
                    $logger->debug($log_prefix."unsupported target event: $query");
                }
            }
        } else {
            map { $_->setNextRunDateFromNow() } @targets;
            $trace = "rescheduling next contact for all targets right now";
        }
    } else {
        $code    = 403;
        $message = "Access denied";
        $trace   = "invalid request (untrusted address)";
    }

    my $template = Text::Template->new(
        TYPE => 'FILE', SOURCE => "$self->{htmldir}/now.tpl"
    );

    my $hash = {
        message => $message
    };

    my $response = HTTP::Response->new(
        $code,
        'OK',
        HTTP::Headers->new('Content-Type' => 'text/html'),
        $template->fill_in(HASH => $hash)
    );

    $client->send_response($response);
    $logger->debug($log_prefix . $trace) if $trace;
    return $code;
}

sub _handle_status {
    my ($self, $client, $request, $clientIp) = @_;

    my $status = $self->{agent}->getStatus();
    my $response = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new('Content-Type' => 'text/plain'),
       "status: ".$status
    );
    $client->send_response($response);
    return 200;
}

sub _isTrusted {
    my ($self, $address) = @_;

    # Reset trusted on expiration
    $self->_handleTrustedAddressesCache();

    foreach my $trusted_addresses (values %{$self->{trust}}) {
        return 1
            if isPartOf(
                $address,
                $trusted_addresses,
                $self->{logger}
            );
    }

    return 0;
}

sub init {
    my ($self) = @_;

    my $logger = $self->{logger};

    $self->{listener} = HTTP::Daemon->new(
        LocalAddr => $self->{ip},
        LocalPort => $self->{port},
        ReuseAddr => 1,
        ReusePort => $OSNAME ne 'MSWin32',
        Timeout   => 1,
        Blocking  => 0
    );

    if (!$self->{listener}) {
        $logger->error($log_prefix . "failed to start the HTTPD service");
        return;
    }

    my $io_poller;

    IO::Poll->require();
    if ($EVAL_ERROR) {
        $logger->debug("Can't use IO::Poll to optimize HTTP requests handling: $!");
    } else {
        $io_poller = IO::Poll->new();
        $io_poller->mask($self->{listener} => IO::Poll::POLLIN);
        $self->{_poller} = $io_poller;
    }

    $logger->info(
        $log_prefix . "HTTPD service started on port $self->{port}"
    );

    # Load any plugin configuration and fix plugins list handled on main port
    my %plugins = map { $_->name() => $_ } @{$self->{_plugins}};
    foreach my $plugin (@{$self->{_plugins}}) {

        next if $plugin->disabled();

        # We handle SSL Plugin differently
        if ($plugin->name() eq 'SSL') {
            my $ports = $plugin->config('ports');
            foreach my $port (@{$ports}) {
                # Handle SSL case on default port
                if (!$port || $port == $self->{port}) {
                    $self->{_ssl} = $plugin;
                    $logger->info($log_prefix . "HTTPD SSL Server plugin enabled on default port");
                    next;
                }
                if (!$self->{listeners}->{$port}) {
                    my $listener = HTTP::Daemon->new(
                            LocalAddr => $self->{ip},
                            LocalPort => $port,
                            ReuseAddr => 1,
                            ReusePort => $OSNAME ne 'MSWin32',
                            Timeout   => 1,
                            Blocking  => 0
                    );
                    unless ($listener) {
                        $logger->error($log_prefix . "failed to start the HTTPD service on port $port for SSL plugin");
                        next;
                    }
                    $self->{listeners}->{$port} = {
                        ssl         => $plugin,
                        listener    => $listener,
                        plugins     => [],
                    };
                    if ($io_poller) {
                        $io_poller = IO::Poll->new();
                        $io_poller->mask($listener => IO::Poll::POLLIN);
                        $self->{_pollers}->{$port} = $io_poller;
                    }
                } else {
                    $self->{listeners}->{$port}->{ssl} = $plugin;
                }
                $logger->info($log_prefix . "HTTPD SSL Server plugin enabled on port $port");
            }
            delete $plugins{$plugin->name()};
            next;
        }

        # Add a port listener if a plugin uses a dedicated port
        my $port = $plugin->port();
        if ($port && $port != $self->{port}) {
            if ($self->{listeners}->{$port}) {
                push @{$self->{listeners}->{$port}->{plugins}}, $plugin;
                $logger->info($log_prefix . "HTTPD ".$plugin->name()." Server plugin also used on port $port");
            } else {
                my $listener = HTTP::Daemon->new(
                        LocalAddr => $self->{ip},
                        LocalPort => $port,
                        ReuseAddr => 1,
                        ReusePort => $OSNAME ne 'MSWin32',
                        Timeout   => 1,
                        Blocking  => 0
                );
                if (!$listener) {
                    $logger->error($log_prefix . "failed to start the HTTPD service on port $port for ".$plugin->name()." plugin");
                    $plugin->disable();
                } else {
                    $self->{listeners}->{$port} = {
                        listener    => $listener,
                        plugins     => [ $plugin ],
                    };
                    $logger->info($log_prefix . "HTTPD ".$plugin->name()." Server plugin also started on port $port");
                    if ($io_poller) {
                        $io_poller = IO::Poll->new();
                        $io_poller->mask($listener => IO::Poll::POLLIN);
                        $self->{_pollers}->{$port} = $io_poller;
                    }
                }
            }
            delete $plugins{$plugin->name()};
        } elsif ($port) {
            $logger->info($log_prefix . "HTTPD ".$plugin->name()." Server plugin also used on main port $self->{port}");
        }
    }
    $self->{_plugins} = [ values(%plugins) ];

    return 1;
}

sub plugins_list {
    my ($self) = @_;

    my @plugins = @{$self->{_plugins}};
    map {
        push @plugins, @{$self->{listeners}->{$_}->{plugins}};
        # Add SSL plugin if it was enabled on a dedicated port
        push @plugins, $self->{listeners}->{$_}->{ssl} if $self->{listeners}->{$_}->{ssl};
    } grep {
        $self->{listeners}->{$_}->{plugins}
    } keys(%{$self->{listeners}}) if $self->{listeners};

    return {
        map {
            my $plugin = $_;
            lc($plugin->name()) => $plugin->disabled ? "disabled" : {
                map { $_ => $plugin->config($_) } keys(%{$plugin->defaults()})
            }
        } @plugins
    };
}

sub needToRestart {
    my ($self, %params) = @_;

    # If no httpd daemon was started, we need to really start it
    return 1 unless $self->{listener};

    # Restart httpd daemon if ip or port changed
    return 1 if ($params{ip} && (!$self->{ip} || $params{ip} ne $self->{ip}));
    return 1 if ($params{port} && (!$self->{port} || $params{port} ne $self->{port}));

    # Reload any plugin configuration and check if port or status has changed
    foreach my $plugin (@{$self->{_plugins}}) {
        my $port = $plugin->port();
        my $disabled = $plugin->disabled();
        $plugin->init();
        return 1 if $port != $plugin->port();
        return 1 if $disabled != $plugin->disabled();
    }

    # Logger may have changed, but then resetting logger ref is sufficient
    $self->{logger} = $params{logger};
    $self->{logger}->debug2(
        $log_prefix . "HTTPD service still listening on port $self->{port}"
    );

    # Be sure to reset computed trusted addresses
    delete $self->{trusted_cache_trust};
    $self->_handleTrustedAddressesCache($params{trust});

    return 0;
}

sub stop {
    my ($self) = @_;

    return unless $self->{listener};

    foreach my $port (keys(%{$self->{listeners}})) {
        $self->{listeners}->{$port}->{listener}->shutdown(2);
        delete $self->{listeners}->{$port};
    }
    $self->{listener}->shutdown(2);

    $self->{logger}->debug($log_prefix . "HTTPD service stopped");

    delete $self->{_plugins};
    delete $self->{listener};
}

sub handleRequests {
    my ($self) = @_;

    return unless $self->{listener}; # init() call failed

    # Avoid an error as Socket::VERSION may contain underscore
    my ($SocketVersion) = split('_',$Socket::VERSION);

    # Handle any timer event on plugins and set next time expected to handle events
    unless ($self->{_timer_event} && $self->{_timer_event} > time) {
        my @enabled_plugins = grep { ! $_->disabled() } @{$self->{_plugins}};
        my ($timeout) = sort grep { $_ } map { $_->timer_event() } @enabled_plugins;
        $self->{_timer_event} = ($timeout && $timeout > time) ? $timeout : time + 60;
    }

    # First try to handle plugin requests on dedicated ports
    my $got_connection = 0;
    foreach my $port (keys(%{$self->{listeners}})) {
        next if $self->{_pollers} && $self->{_pollers}->{$port} &&
            ! $self->{_pollers}->{$port}->poll(0);
        my ($client, $socket) = $self->{listeners}->{$port}->{listener}->accept();
        next unless $socket;

        $got_connection++;

        # Upgrade to SSL if required
        my $ssl = $self->{listeners}->{$port}->{ssl};
        if ($ssl && !$ssl->upgrade_SSL($client)) {
            $self->{logger}->debug($log_prefix . "HTTPD can't start SSL session");
            next;
        }

        my $family = sockaddr_family($socket);
        my $iaddr  = $family == AF_INET  ? unpack_sockaddr_in($socket)  :
                     $family == AF_INET6 ? unpack_sockaddr_in6($socket) :
                     INADDR_ANY;
        my $clientIp;
        # Compatibility: Socket::inet_ntop() is only available since perl 5.12 introducing Socket v1.87
        if ($SocketVersion >= 1.87) {
            $clientIp = Socket::inet_ntop($family, $iaddr);
        } else {
            my (undef, $iaddr) = sockaddr_in($socket);
            $clientIp = inet_ntoa($iaddr);
        }
        my $request = $client->get_request();
        $self->_handle_plugins($client, $request, $clientIp, $self->{listeners}->{$port}->{plugins}, MaxKeepAlive);
    }

    return unless $self->{listener}; # in case of config reload()

    return $got_connection if $self->{_poller} && ! $self->{_poller}->poll(0);

    my ($client, $socket) = $self->{listener}->accept();
    return $got_connection unless $socket;

    $got_connection++;

    # Upgrade to SSL if required
    if ($self->{_ssl} && !$self->{_ssl}->upgrade_SSL($client)) {
        $self->{logger}->debug($log_prefix . "HTTPD can't start SSL session");
        return $got_connection;
    }

    my $family = sockaddr_family($socket);
    my $iaddr  = $family == AF_INET  ? unpack_sockaddr_in($socket)  :
                 $family == AF_INET6 ? unpack_sockaddr_in6($socket) :
                 INADDR_ANY;
    my $clientIp;
    # Compatibility: Socket::inet_ntop() is only available since perl 5.12 introducing Socket v1.87
    if ($SocketVersion >= 1.87) {
        $clientIp = Socket::inet_ntop($family, $iaddr);
    } else {
        my (undef, $iaddr) = sockaddr_in($socket);
        $clientIp = inet_ntoa($iaddr);
    }
    my $request = $client->get_request();
    $self->_handle($client, $request, $clientIp, MaxKeepAlive);

    $self->{_timer_event} = time+10
        if ($self->{_timer_event} > time+10);

    return $got_connection;
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Server - An embedded HTTP server

=head1 DESCRIPTION

This is the server used by the agent to listen on the network for messages sent
by OCS or GLPI servers.

It is an HTTP server listening on port 62354 (by default). The following
requests are accepted:

=over

=item /status

=item /deploy

=item /now

=back

Authentication is based on connection source address: trusted requests are
accepted, other are rejected.

=head1 CLASS METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use

=item I<htmldir>

the directory where HTML templates and static files are stored

=item I<ip>

the network address to listen to (default: all)

=item I<port>

the network port to listen to

=item I<trust>

an IP address or an IP address range from which to trust incoming requests
(default: none)

=back

=head1 INSTANCE METHODS

=head2 $server->init()

Start the server internal listener.

=head2 $server->handleRequests()

Check if there any incoming request, and honours it if needed. Returns the number
of handled connections.
