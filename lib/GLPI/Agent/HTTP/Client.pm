package GLPI::Agent::HTTP::Client;

use strict;
use warnings;

use English qw(-no_match_vars);
use URI;
use HTTP::Status;
use LWP::UserAgent;
use UNIVERSAL::require;

use GLPI::Agent;
use GLPI::Agent::Logger;
use GLPI::Agent::Tools;

my $log_prefix = "[http client] ";

sub new {
    my ($class, %params) = @_;

    my $config = $params{config} // {};

    my $ca_cert_file = $params{ca_cert_file} || $config->{'ca-cert-file'};
    die "non-existing certificate file $ca_cert_file"
        if $ca_cert_file && ! -f $ca_cert_file;

    my $ca_cert_dir = $params{ca_cert_dir} || $config->{'ca-cert-dir'};
    die "non-existing certificate directory $ca_cert_dir"
        if $ca_cert_dir && ! -d $ca_cert_dir;

    my $ssl_cert_file = $params{ssl_cert_file} || $config->{'ssl-cert-file'};
    die "non-existing client certificate file $ssl_cert_file"
        if $ssl_cert_file && ! -f $ssl_cert_file;

    my $self = {
        logger          => $params{logger} || GLPI::Agent::Logger->new(),
        user            => $params{user}     || $config->{'user'},
        password        => $params{password} || $config->{'password'},
        ssl_set         => 0,
        no_ssl_check    => $params{no_ssl_check} || $config->{'no-ssl-check'},
        no_compress     => $params{no_compress}  || $config->{'no-compression'},
        ca_cert_dir     => $ca_cert_dir,
        ca_cert_file    => $ca_cert_file,
        ssl_cert_file   => $ssl_cert_file,
        ssl_fingerprint => $params{ssl_fingerprint} || $config->{'ssl-fingerprint'},
        _vardir         => $config->{'vardir'},
    };
    bless $self, $class;

    # create user agent
    $self->{ua} = LWP::UserAgent->new(
        requests_redirectable => ['POST', 'GET', 'HEAD'],
        agent                 => $GLPI::Agent::AGENT_STRING,
        timeout               => $params{timeout} || $config->{'timeout'} || 180,
        parse_head            => 0, # No need to parse HTML
        keep_alive            => 1,
    );

    my $proxy = $params{proxy} || $config->{'proxy'};
    if ($proxy) {
        $self->{ua}->proxy(['http', 'https'], $proxy);
    }  else {
        $self->{ua}->env_proxy();
    }

    return $self;
}

sub request {
    my ($self, $request, $file, $no_proxy_host, $timeout, %skiperror) = @_;

    my $logger = $self->{logger};

    # Save current timeout to restore it before leaving
    my $current_timeout = $self->{ua}->timeout();
    $self->{ua}->timeout($timeout)
        if defined($timeout);

    my $url = $request->uri();
    my $scheme = $url->scheme();
    $self->_setSSLOptions() if $scheme eq 'https' && !$self->{ssl_set};

    # Avoid to use proxy if requested
    if ($no_proxy_host) {
        $self->{ua}->no_proxy($no_proxy_host);
    } elsif ($self->{ua}->proxy($scheme)) {
        # keep proxy trace if one may be used
        my $proxy_uri = URI->new($self->{ua}->proxy($scheme));
        if ($proxy_uri->userinfo) {
            # Obfuscate proxy password if present
            my ($proxy_user, $proxy_pass) = split(':', $proxy_uri->userinfo);
            $proxy_uri->userinfo( $proxy_user.":".('X' x length($proxy_pass)) )
                if ($proxy_pass);
        }
        $logger->debug(
            $log_prefix .
            "Using '".$proxy_uri->as_string()."' as proxy for $scheme protocol"
        );
    }

    my $result = HTTP::Response->new( 500 );
    eval {
        if ($OSNAME eq 'MSWin32' && $scheme eq 'https') {
            alarm $self->{ua}->timeout();
        }
        $result = $self->{ua}->request($request, $file);
        alarm 0;
    };

    # Debug SSL support status when no requesting security
    if ($self->{no_ssl_check}) {
        my $headers = $result->headers();
        my $warning = $headers->header("Client-SSL-Warning");
        $logger->info($log_prefix . "SSL Client warning: $warning") if $warning;

        my $class = $headers->header("Client-SSL-Socket-Class");
        if ($class && $class eq "IO::Socket::SSL") {
            my $infos = "";
            foreach my $header (qw/Client-SSL-Cert-Issuer Client-SSL-Cert-Subject Client-SSL-Version Client-SSL-Cipher/) {
                my $string = $headers->header($header)
                    or next;
                $infos .= ", " if $infos;
                $header =~ /^Client-SSL-(.*)$/;
                $infos .= "$1: '$string'";
            }
            $logger->info($log_prefix . "SSL Client info: $infos") if $infos;

            my $fingerprint;
            my ($socket) = $self->{ua}->conn_cache->get_connections('https');
            $fingerprint = $socket->get_fingerprint() if $socket;
            if ($fingerprint) {
                $logger->info($log_prefix . "SSL server certificate fingerprint: $fingerprint");
                $logger->info($log_prefix . "You can set it in conf as 'ssl-fingerprint' and disable 'no-ssl-check' option to trust that server certificate");
            }
        }
    }

    # check result first
    if (!$result->is_success()) {
        # authentication required
        if ($result->code() == 401) {
            if ($self->{user} && $self->{password}) {
                $logger->debug(
                    $log_prefix .
                    "authentication required, submitting credentials"
                );
                # compute authentication parameters
                my @headers = split(/\s*,\s*/, $result->header('www-authenticate'));
                # Parse headers for supported scheme
                my %authenticate;
                foreach my $header (@headers) {
                    if ($header =~ /^Basic realm="(.*)"/) {
                        $authenticate{basic} = $1;
                    }
                }
                my @authen;
                push @authen, 'basic' if $authenticate{basic};
                my $host = $url->host();
                my $port = $url->port() ||
                   ($scheme eq 'https' ? 443 : 80);
                foreach my $authen (@authen) {
                    $logger->debug(
                        $log_prefix .
                        "authentication required, trying $authen with $self->{user} user" .
                        ( $authenticate{$authen} ? " ($authenticate{$authen})" : "" )
                    );
                    $self->{ua}->credentials(
                        "$host:$port",
                        $authenticate{$authen},
                        $self->{user},
                        $self->{password},
                    );
                    # replay request
                    eval {
                        if ($OSNAME eq 'MSWin32' && $scheme eq 'https') {
                            alarm $self->{ua}->{timeout};
                        }
                        $result = $self->{ua}->request($request, $file);
                        alarm 0;
                    };
                    last if $result->is_success();
                    $logger->debug("$log_prefix$authen authentication failed");
                }
                if (!$result->is_success()) {
                    $logger->error(
                        $log_prefix .
                        ($result->code() == 401 ?
                            "authentication required, wrong credentials" :
                            "authentication required, error status: " . $result->status_line())
                    );
                }
            } else {
                # abort
                $logger->error(
                    $log_prefix .
                    "authentication required, no credentials available"
                );
            }

        } elsif ($result->code() == 407) {
            $logger->error(
                $log_prefix .
                "proxy authentication required, wrong or no proxy credentials"
            );

        } else {
            # check we request through a proxy
            my $proxyreq = defined $result->request->{proxy};

            my $message;
            my $contentType = $result->header('content-type');
            if ($contentType && $contentType eq 'application/json' && $result->header('content-length')) {
                if (GLPI::Agent::Protocol::Message->require()) {
                    my $content = GLPI::Agent::Protocol::Message->new(message => $result->content());
                    if ($content->status eq 'error' && $content->get('message')) {
                        $message = $content->get('message');
                    }
                }
            }

            # Add info if the error comes from the client itself
            my $error_type = ($proxyreq ? "proxy" : "communication")." error";
            my $warning = $result->header('client-warning') // '';
            $error_type = lc($warning) if $warning;

            $logger->error(
                $log_prefix . $error_type . ": " . $result->status_line() . ($message ? ", $message" : "")
            ) unless $skiperror{$result->code()};
        }
    }

    # Always restore timeout
    $self->{ua}->timeout($current_timeout);

    return $result;
}

sub _setSSLOptions {
    my ($self) = @_;

    # SSL handling
    if ($self->{no_ssl_check}) {
       # LWP 6 default behaviour is to check hostname
       # Fedora also backported this behaviour change in its LWP5 package, so
       # just checking on LWP version is not enough
       $self->{ua}->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0)
           if $self->{ua}->can('ssl_opts');
    } else {
        # only IO::Socket::SSL can perform full server certificate validation,
        # Net::SSL is only able to check certification authority, and not
        # certificate hostname
        IO::Socket::SSL->require();
        die
            "IO::Socket::SSL Perl module not available, "              .
            "unable to validate SSL certificates "                     .
            "(workaround: use 'no-ssl-check' configuration parameter)"
            if $EVAL_ERROR;

        # Activate SSL Debug if Stderr is in backends
        my $DEBUG_SSL = 0;
        $DEBUG_SSL = grep { ref($_) =~/Stderr$/ } @{$self->{logger}{backends}}
            if (ref($self->{logger}{backends}) eq 'ARRAY');
        if ( $DEBUG_SSL && $self->{logger}->debug_level() >= 2 ) {
            $Net::SSLeay::trace = 3;
        }

        # Support system specific certificate store
        unless ($self->{ca_cert_file} || $self->{ca_cert_dir}) {
            # Support keychain on Darwin and keystore on MSWin32
            $self->{ca_cert_file} = $self->_KeyChain_or_KeyStore_Export()
                if $OSNAME =~ /^darwin|MSWin32$/;
        }

        if ($LWP::VERSION >= 6) {
            $self->{ua}->ssl_opts(SSL_ca_file => $self->{ca_cert_file})
                if $self->{ca_cert_file};
            $self->{ua}->ssl_opts(SSL_ca_path => $self->{ca_cert_dir})
                if $self->{ca_cert_dir};
            $self->{ua}->ssl_opts(SSL_cert_file => $self->{ssl_cert_file})
                if $self->{ssl_cert_file};
            $self->{ua}->ssl_opts(SSL_fingerprint => $self->{ssl_fingerprint})
                if $self->{ssl_fingerprint};
        } else {
            # SSL_verifycn_scheme and SSL_verifycn_name are required
            die
                "IO::Socket::SSL Perl module too old "                     .
                "(available: $IO::Socket::SSL::VERSION, required: 1.14), " .
                "unable to validate SSL certificates "                     .
                "(workaround: use 'no-ssl-check' configuration parameter)"
                if $IO::Socket::SSL::VERSION < 1.14;

            # use a custom HTTPS handler to workaround default LWP5 behaviour
            GLPI::Agent::HTTP::Protocol::https->use(
                ca_cert_file => $self->{ca_cert_file},
                ca_cert_dir  => $self->{ca_cert_dir},
                ssl_cert_file => $self->{ssl_cert_file},
                ssl_fingerprint => $self->{ssl_fingerprint},
            );

            LWP::Protocol::implementor(
                'https', 'GLPI::Agent::HTTP::Protocol::https'
            );

            # abuse user agent internal to pass values to the handler, so
            # as to have different behaviors in the same process
            $self->{ua}->{ssl_check} = $self->{no_ssl_check} ? 0 : 1;
        }
    }

    $self->{ssl_set} = 1;
}

sub _KeyChain_or_KeyStore_Export {
    my ($self) = @_;

    my $logger = $self->{logger};
    my $vardir = $self->{_vardir};
    my $basename = $OSNAME eq 'darwin'  ? "keychain" : "keystore";
    unless (defined($self->{_certchain})) {
        if ($vardir && -d $vardir) {
            $self->{_certchain} = "$vardir/$basename-export.pem" ;
            $self->{_certchain_mtime} = (stat($self->{_certchain}))[9]
                if -e $self->{_certchain};
        } else {
            File::Temp->require();
            if ($EVAL_ERROR) {
                $logger->error("Can't load File::Temp to store $basename export");
                return;
            }
            # Store File::Temp object with client so the temp file is kept until
            # the object is destroyed and no more used
            $self->{_certchain_temp} = File::Temp->new(
                TEMPLATE    => "$basename-export-XXXXXX",
                SUFFIX      => ".pem",
            );
            $self->{_certchain} = $self->{_certchain_temp}->filename();
        }
    }

    # The server certificate file won't be regenerated before agent program next start
    # or it has been generated more than an hour ago
    return $self->{_certchain}
        if $self->{_certchain_mtime} && $BASETIME < $self->{_certchain_mtime}
            && $self->{_certchain_mtime} > time - 3600;

    $logger->debug(
        $log_prefix .
        (-e $self->{_certchain} ? "Updating" : "Creating") .
        " '".$self->{_certchain}."' file to store $basename known certificates"
    );

    if ($OSNAME eq 'darwin') {
        getAllLines(
            command => "security find-certificate -a -p > '".$self->{_certchain}."'",
            logger  => $logger
        );
    } else {
        # Windows keystore support
        Cwd->require();
        my $cwd = Cwd::cwd();

        File::Temp->require();
        if ($EVAL_ERROR) {
            $logger->error("Can't load File::Temp to export $basename certificates");
            return;
        }

        # Create a temporary folder in vardir to cd & export certificates
        my $tmpdir = File::Temp->newdir(
            TEMPLATE    => "$basename-export-XXXXXX",
            DIR         => $vardir,
            TMPDIR      => 1,
        );
        my $certdir = $tmpdir->dirname;
        $certdir =~ s{\\}{/}g;
        my $fhw;
        if (-d $certdir && open($fhw, ">", $self->{_certchain})) {
            $logger->debug2("Changing to '$certdir' temporary folder");
            chdir $certdir;

            # Export certificates from keystore as crt files
            getAllLines(
                command => "certutil -Store -Silent -Split",
                logger  => $logger
            );
            getAllLines(
                command => "certutil -Store -Silent -Enterprise -Split",
                logger  => $logger
            );

            # Convert each crt file to base64 encoded cer file and concatenate in certchain file
            File::Glob->require();
            foreach my $certfile (File::Glob::bsd_glob("$certdir/*")) {
                if ($certfile =~ m{^$certdir/(.*\.crt)$}) {
                    getAllLines(
                        command => "certutil -encode $1 temp.cer",
                        logger  => $logger
                    );
                    my $fhr;
                    if (open($fhr, "<", "temp.cer")) {
                        map { print $fhw $_ } <$fhr>;
                        close($fhr);
                    }
                    unlink "$certdir/temp.cer";
                }
                unlink $certfile;
            }

            close($fhw);

            # Get back to current dir
            $logger->debug2("Changing back to '$cwd' folder");
            chdir $cwd;
        }
    }

    $self->{_certchain_mtime} = time;
    return $self->{_certchain} if -s $self->{_certchain};

    # Finally we should cache we got an empty result
    unlink $self->{_certchain};
    return $self->{_certchain} = "";
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Client - An abstract HTTP client

=head1 DESCRIPTION

This is an abstract class for HTTP clients. It can send messages through HTTP
or HTTPS, directly or through a proxy, and validate SSL certificates.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<proxy>

the URL of an HTTP proxy

=item I<user>

the user for HTTP authentication

=item I<password>

the password for HTTP authentication

=item I<no_ssl_check>

a flag allowing to ignore untrusted server certificates (default: false)

=item I<ca_cert_file>

the file containing trusted certificates

=item I<ca_cert_dir>

the directory containing trusted certificates

=back

=head2 request($request)

Send given HTTP::Request object, handling SSL checking and user authentication
automatically if needed.
