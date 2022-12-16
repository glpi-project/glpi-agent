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

use constant    _log_prefix => "[http client] ";

# Keep SSL_ca for storing read local certificate store at the class level
my $_SSL_ca;

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

    # check compression mode
    if (!$self->{no_compress} && Compress::Zlib->require()) {
        # RFC 1950
        $self->{compression} = 'zlib';
        $self->{logger}->debug2(_log_prefix . "Using Compress::Zlib for compression");
    } elsif (!$self->{no_compress} && canRun('gzip')) {
        # RFC 1952
        $self->{compression} = 'gzip';
        $self->{logger}->debug2(_log_prefix . "Using gzip for compression");
    } else {
        $self->{compression} = 'none';
        $self->{logger}->debug2(_log_prefix . "Not using compression");
    }

    # Set content-type header relative to selected compression
    $self->{ua}->default_header('Content-type' =>
        $self->{compression} eq 'zlib' ? "application/x-compress-zlib" :
        $self->{compression} eq 'gzip' ? "application/x-compress-gzip" :
                                         "application/json"
    );

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
            _log_prefix .
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
        $logger->info(_log_prefix . "SSL Client warning: $warning") if $warning;

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
            $logger->info(_log_prefix . "SSL Client info: $infos") if $infos;

            # fingerprint IO::Socket::SSL API is only available since IO::Socket::SSL v1.967
            if ($IO::Socket::SSL::VERSION >= 1.967) {
                my $fingerprint;
                my ($socket) = $self->{ua}->conn_cache->get_connections('https');
                $fingerprint = $socket->get_fingerprint() if $socket;
                if ($fingerprint) {
                    $logger->info(_log_prefix . "SSL server certificate fingerprint: $fingerprint");
                    $logger->info(_log_prefix . "You can set it in conf as 'ssl-fingerprint' and disable 'no-ssl-check' option to trust that server certificate");
                }
            }
        }
    }

    # check result first
    if (!$result->is_success()) {
        # authentication required
        if ($result->code() == 401) {
            if ($self->{user} && $self->{password}) {
                $logger->debug(
                    _log_prefix .
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
                        _log_prefix .
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
                    $logger->debug(_log_prefix."$authen authentication failed");
                }
                if (!$result->is_success()) {
                    $logger->error(
                        _log_prefix .
                        ($result->code() == 401 ?
                            "authentication required, wrong credentials" :
                            "authentication required, error status: " . $result->status_line())
                    );
                }
            } else {
                # abort
                $logger->error(
                    _log_prefix .
                    "authentication required, no credentials available"
                );
            }

        } elsif ($result->code() == 407) {
            $logger->error(
                _log_prefix .
                "proxy authentication required, wrong or no proxy credentials"
            );

        } else {
            # check we request through a proxy
            my $proxyreq = defined $result->request->{proxy};

            my @message = ($result->status_line());
            my $contentType = $result->header('content-type');
            my $message = $result->content();
            $message = $self->uncompress($message, $contentType) if $contentType && $contentType =~ /x-compress/;
            if ($message && $message =~ /^{/) {
                if (GLPI::Agent::Protocol::Message->require()) {
                    my $content = GLPI::Agent::Protocol::Message->new(message => $message);
                    if ($content->status eq 'error' && $content->get('message')) {
                        push @message, $content->get('message');
                    }
                }
            } elsif ($message && $message =~ /^</) {
                if (GLPI::Agent::XML->require()) {
                    my $xml = GLPI::Agent::XML->new(string => $message);
                    my $tree = $xml->dump_as_hash();
                    push @message, grep { $_ } split("\n", $tree->{REPLY}->{ERROR})
                        if $tree && ref($tree->{REPLY}) eq 'HASH' && exists($tree->{REPLY}->{ERROR});
                }
            }

            # Add info if the error comes from the client itself
            my $error_type = ($proxyreq ? "proxy" : "communication")." error";
            my $warning = $result->header('client-warning') // '';
            $error_type = lc($warning) if $warning;

            # Eventually add detailed SSL error message
            if ($self->{ssl_set} && $IO::Socket::SSL::SSL_ERROR) {
                my $strcheck = IO::Socket::SSL::SSL_WANT_READ()."|".IO::Socket::SSL::SSL_WANT_WRITE();
                push @message, $IO::Socket::SSL::SSL_ERROR
                    unless $IO::Socket::SSL::SSL_ERROR =~ /$strcheck/;
            }

            $logger->error(
                _log_prefix . $error_type . ": " . join(", ", @message)
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

        # Support keychain on Darwin and keystore on MSWin32
        # But not if ca-cert-dir option is used
        my $SSL_ca;
        $SSL_ca = $self->_KeyChain_or_KeyStore_Export()
            unless $self->{ca_cert_dir};

        if ($LWP::VERSION >= 6) {
            $self->{ua}->ssl_opts(SSL_ca_file => $self->{ca_cert_file})
                if $self->{ca_cert_file};
            $self->{ua}->ssl_opts(SSL_ca_path => $self->{ca_cert_dir})
                if $self->{ca_cert_dir};
            $self->{ua}->ssl_opts(SSL_cert_file => $self->{ssl_cert_file})
                if $self->{ssl_cert_file};
            $self->{ua}->ssl_opts(SSL_fingerprint => $self->{ssl_fingerprint})
                if $self->{ssl_fingerprint} && $IO::Socket::SSL::VERSION >= 1.967;
            # Use SSL_ca option to support system keychain or keystore to add
            # discovered certificates to public ones
            $self->{ua}->ssl_opts(SSL_ca => $SSL_ca)
                if $SSL_ca && @{$SSL_ca};
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
                ssl_ca => $SSL_ca,
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

    return unless $OSNAME =~ /^darwin|MSWin32$/;

    my $logger = $self->{logger};
    my $vardir = $self->{_vardir};
    my $basename = $OSNAME eq 'darwin'  ? "keychain" : "keystore";
    unless (defined($_SSL_ca)) {
        # Just clean up file that could have been created by glpi-agent v1.3
        if ($vardir && -d $vardir) {
            my $obsolete = "$vardir/$basename-export.pem";
            unlink $obsolete if -e $obsolete;
        }
    }

    # Read certificates are cached for one hour after the service is started
    return $_SSL_ca->{_certs}
        if $_SSL_ca->{_expiration} && time < $_SSL_ca->{_expiration};

    $logger->debug(
        _log_prefix .
        ($_SSL_ca ? "Updating" : "Reading") . " $basename known certificates"
    );

    my @certs = ();
    IO::Socket::SSL::Utils->require();

    File::Temp->require();
    if ($EVAL_ERROR) {
        $logger->error("Can't load File::Temp to export $basename certificates");
        return;
    }

    if ($OSNAME eq 'darwin') {
        my $tmpfile = File::Temp->new(
            TEMPLATE    => "$basename-export-XXXXXX",
            DIR         => $vardir,
            SUFFIX      => ".pem",
        );
        my $file = $tmpfile->filename;
        getAllLines(
            command => "security find-certificate -a -p > '$file'",
            logger  => $logger
        );
        @certs = IO::Socket::SSL::Utils::PEM_file2certs($file)
            if -s $file;
    } else {
        # Windows keystore support
        Cwd->require();
        my $cwd = Cwd::cwd();

        # Create a temporary folder in vardir to cd & export certificates
        my $tmpdir = File::Temp->newdir(
            TEMPLATE    => "$basename-export-XXXXXX",
            DIR         => $vardir,
            TMPDIR      => 1,
        );
        my $certdir = $tmpdir->dirname;
        $certdir =~ s{\\}{/}g;
        if (-d $certdir) {
            $logger->debug2("Changing to '$certdir' temporary folder");
            chdir $certdir;

            # Export certificates from keystore as crt files
            getAllLines(
                command => "certutil -Silent -Split -Store CA",
                logger  => $logger
            );
            getAllLines(
                command => "certutil -Silent -Split -Store Root",
                logger  => $logger
            );
            getAllLines(
                command => "certutil -Silent -Split -Enterprise -Store CA",
                logger  => $logger
            );
            getAllLines(
                command => "certutil -Silent -Split -Enterprise -Store Root",
                logger  => $logger
            );
            getAllLines(
                command => "certutil -Silent -Split -GroupPolicy -Store CA",
                logger  => $logger
            );
            getAllLines(
                command => "certutil -Silent -Split -GroupPolicy -Store Root",
                logger  => $logger
            );
            getAllLines(
                command => "certutil -Silent -Split -User -Store CA",
                logger  => $logger
            );
            getAllLines(
                command => "certutil -Silent -Split -User -Store Root",
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
                    push @certs, IO::Socket::SSL::Utils::PEM_file2cert("$certdir/temp.cer")
                        if -s "$certdir/temp.cer";
                    unlink "$certdir/temp.cer";
                }
                unlink $certfile;
            }

            # Get back to current dir
            $logger->debug2("Changing back to '$cwd' folder");
            chdir $cwd;
        }
    }

    # Update class level datas
    $_SSL_ca->{_expiration} = time + 3600;
    return $_SSL_ca->{_certs} = \@certs;
}

sub compress {
    my ($self, $data) = @_;

    return
        $self->{compression} eq 'zlib' ? Compress::Zlib::compress($data) :
        $self->{compression} eq 'gzip' ? $self->_compressGzip($data)     :
                                         $data;
}

sub uncompress {
    my ($self, $data, $type) = @_;

    if ($type) {
        $type =~ s|^application/||i;
    } else {
        $type = "unspecified";
    }

    if ($type =~ /^x-compress-zlib$/i) {
        $self->{logger}->debug2("format: Zlib");
        return Compress::Zlib::uncompress($data);
    } elsif ($type =~ /^x-compress-gzip$/i) {
        $self->{logger}->debug2("format: Gzip");
        return $self->_uncompressGzip($data);
    } elsif ($type =~ /^json$/i) {
        $self->{logger}->debug2("format: JSON");
        return $data;
    } elsif ($type =~ /^xml$/i) {
        $self->{logger}->debug2("format: XML");
        return $data;
    } elsif ($data =~ /^\s*(\{.*\})\s*$/s) {
        $self->{logger}->debug2("format: JSON detected");
        return $1;
    } elsif ($data =~ /^<\?xml version/) {
        $self->{logger}->debug2("format: XML detected");
        return $data;
    } elsif ($data =~ /(<html><\/html>|)[^<]*(<.*>)\s*$/s) {
        $self->{logger}->debug2("format: Plaintext");
        return $2;
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

    my $result = getAllLines(
        command => 'gzip -c ' . $in->filename(),
        logger  => $self->{logger}
    );

    return $result;
}

sub _uncompressGzip {
    my ($self, $data) = @_;

    my $in = File::Temp->new();
    print $in $data;
    close $in;

    my $result = getAllLines(
        command => 'gzip -dc ' . $in->filename(),
        logger  => $self->{logger}
    );

    return $result;
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

=item I<config>

the GLPI::Agent::Config object where to find agent SSL related options

=back

=head2 request($request)

Send given HTTP::Request object, handling SSL checking and user authentication
automatically if needed.
