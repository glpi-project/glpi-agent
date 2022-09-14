package GLPI::Agent::Task::RemoteInventory::Remote;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use URI;
use Socket qw(getaddrinfo getnameinfo);

use GLPI::Agent::Tools::Network;

use constant    supported => 0;

use constant    supported_modes => ();

sub new {
    my ($class, %params) = @_;

    my $dump = $params{dump} // {};

    my $self = {
        _expiration => $dump->{expiration} // 0,
        _deviceid   => $dump->{deviceid}   // '',
        _url        => $dump->{url}        // $params{url},
        _config     => $params{config}     // {},
        _user       => $ENV{USERNAME},
        _pass       => $ENV{PASSWORD},
        _modes      => {},
        logger      => $params{logger},
    };

    bless $self, $class;

    my $url = URI->new($self->{_url});
    my $scheme = $url->scheme();
    if (!$scheme) {
        $scheme = 'ssh';
        $url->scheme($scheme);
        $url->host($self->{_url});
        $url->path('');
        $self->{_url} = $url->as_string;
    }

    my $subclass = ucfirst($scheme);
    $class .= '::'.$subclass;
    $class->require();
    if ($EVAL_ERROR) {
        $self->{logger}->debug("Failed to load $class module: $EVAL_ERROR");
        $self->{logger}->error("Skipping '$self->{_url}' remote: $EVAL_ERROR");
        return $self;
    }

    $self->{_protocol} = $scheme;

    # Check for mode, name & deviceid in url params
    my $query = $url->query() // '';
    my ($mode) = $query =~ /\bmode=(\w+)\b/;
    unless ($self->{_deviceid}) {
        # Ignore deviceid params when provided by dump
        my ($deviceid) = $query =~ /\bdeviceid=([\w.-]+)\b/;
        $self->{_deviceid} = $deviceid if $deviceid;
    }

    bless $self, $class;

    # Update supported modes
    if ($mode) {
        foreach my $key (split('_', lc($mode))) {
            if (grep { $_ eq $key } $self->supported_modes()) {
                $self->{_modes}->{$key} = 1;
            } else {
                $self->{logger}->debug("Unsupported remote mode: $key") if $self->{logger};
            }
        }
        $self->{logger}->debug("Remote mode enabled: ".join(' ', keys(%{$self->{_modes}})))
            if $self->{logger} && keys(%{$self->{_modes}});
    }

    $self->handle_url($url);

    return $self;
}

sub handle_url {
    my ($self, $url) = @_;

    $self->{_host} = $url->host;
    $self->{_port} = $url->port;
    my $userinfo = $url->userinfo;
    if ($userinfo) {
        my ($user, $pass) = split(/:/, $userinfo);
        $self->user($user);
        $self->pass($pass) if defined($pass);
    }
}

sub prepare {}

sub checking_error {}

sub disconnect {}

sub host {
    my ($self, $hostname) = @_;

    $self->{_host} = $hostname if $hostname;

    return $self->{_host} // '';
}

sub port {
    my ($self, $port) = @_;

    $self->{_port} = $port if $port;

    return $self->{_port} // 0;
}

sub user {
    my ($self, $user) = @_;

    $self->{_user} = $user if defined($user);

    return $self->{_user} // '';
}

sub pass {
    my ($self, $pass) = @_;

    $self->{_pass} = $pass if defined($pass);

    return $self->{_pass} // '';
}

sub mode {
    my ($self, $mode) = @_;

    return $self->{_modes}->{$mode} if defined($mode);

    return $self->{_modes};
}

sub worker {
    my ($self, $worker) = @_;

    return $self->{_worker} = $worker if $worker;

    return $self->{_worker} // 0;
}

sub retry {
    my ($self, $delay) = @_;

    if (defined($delay)) {
        $self->{_retry} = $delay;
        $self->expiration(time+$delay) if $delay;
    }

    return $self->{_retry} ? $self : 0;
}

sub deviceid {
    my ($self, %params) = @_;

    # Deviceid could be reset after the real hostname is known or if read from the host
    $self->{_deviceid} = $params{deviceid} if $params{deviceid};

    # If not defined, use same algorithm than in Inventory module
    unless ($self->{_deviceid}) {
        # Try to resolve address is host given as an ip
        my $hostname = $params{hostname} || $self->host();
        if ($hostname =~ $ip_address_pattern) {
            my $info = getaddrinfo($hostname);
            if (ref($info) && $info->{addr}) {
                my ($err, $name) = getnameinfo($info->{addr});
                $hostname = $name if $name;
            }
        }

        $hostname =~ s/\..*$// unless $hostname =~ $ip_address_pattern;

        my ($year, $month , $day, $hour, $min, $sec) = (localtime(time))[5, 4, 3, 2, 1, 0];

        $self->{_deviceid} = sprintf("$hostname-%02d-%02d-%02d-%02d-%02d-%02d",
            $year + 1900, $month + 1, $day, $hour, $min, $sec);
    }

    return $self->{_deviceid} // '';
}

sub config {
    my ($self) = @_;

    return $self->{_config};
}

sub protocol {
    my ($self) = @_;

    return $self->{_protocol};
}

sub expiration {
    my ($self, $timeout) = @_;

    $self->{_expiration} = $timeout if defined($timeout);

    return $self->{_expiration};
}

sub dump {
    my ($self) = @_;

    # deviceid is mandatory to store remotes
    return unless $self->{_deviceid};

    my $dump = {
        deviceid    => $self->{_deviceid},
        url         => $self->{_url},
        protocol    => $self->{_protocol},
        expiration  => $self->{_expiration},
    };

    return $dump;
}

sub url {
    my ($self) = @_;

    return $self->{_url};
}

sub safe_url {
    my ($self) = @_;

    return $self->{_url} if $self->config && $self->config->{'show-passwords'};

    my $pass = $self->pass();
    return $self->{_url} unless length($pass);

    my $url = $self->{_url};
    $url =~ s/:$pass/:****/;

    return $url;
}

sub getRemoteFirstLine {
    my ($self, %params) = @_;

    my $handle = $self->getRemoteFileHandle(%params);
    return unless $handle;

    my $result = <$handle>;
    close $handle;

    chomp $result if defined $result;
    return $result;
}

sub getRemoteAllLines {
    my ($self, %params) = @_;

    my $handle = $self->getRemoteFileHandle(%params);
    return unless $handle;

    if (wantarray) {
        my @lines = map { chomp; $_ } <$handle>;
        close $handle;
        return @lines;
    } else {
        local $RS;
        my $lines = <$handle>;
        close $handle;
        return $lines;
    }
}

1;
