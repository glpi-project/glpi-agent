package FusionInventory::Agent::Task::RemoteInventory::Remote;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use URI;
use Socket qw(getaddrinfo getnameinfo);

use FusionInventory::Agent::Tools::Network;

my $supported_protocols = qr/^ssh|winrm$/;

sub new {
    my ($class, %params) = @_;

    my $dump = $params{dump} // {};

    my $self = {
        _expiration => $dump->{expiration} // 0,
        _deviceid   => $dump->{deviceid}   // '',
        _url        => $dump->{url}        // $params{url},
        _config     => $params{config}     // {},
        logger      => $params{logger},
    };

    my $url = URI->new($self->{_url});
    my $scheme = $url->scheme();
    if (!$scheme) {
        $scheme = 'ssh';
        $url->scheme($scheme);
        $url->host($self->{_url});
        $url->path('');
        $self->{_url} = $url->as_string;
    } elsif ($scheme !~ $supported_protocols) {
        $self->{logger}->error("Skipping '$self->{_url}' remote with unsupported '$scheme' protocol");
        return;
    }

    my $subclass = ucfirst($scheme);
    $class .= '::'.$subclass;
    $class->require();
    if ($EVAL_ERROR) {
        $self->{logger}->debug("Failed to load $class module: $EVAL_ERROR");
        $self->{logger}->error("Skipping '$self->{_url}' remote: class loading failure");
        return;
    }

    # URI::winrm class is loaded with Remote::Winrm, so bless the URI object now
    bless $url, "URI::winrm" if $scheme eq "winrm";

    $self->{_protocol} = $scheme;
    $self->{_host} = $url->host;
    my $userinfo = $url->userinfo;
    if ($userinfo) {
        my ($user, $pass) = split(/:/, $userinfo);
        $self->{_user} = $user;
        $self->{_pass} = $pass if defined($pass);
    }

    # Check for mode, name & deviceid in url params
    my $query = $url->query() // '';
    my ($mode) = $query =~ /\bmode=(\w+)\b/;
    $self->{_mode} = $mode if $mode;
    my ($hostname) = $query =~ /\b(?:host)?name=(\w+)\b/;
    $self->{_host} = $hostname if $hostname;
    unless ($self->{_deviceid}) {
        # Ignore deviceid params when provided by dump
        my ($deviceid) = $query =~ /\bdeviceid=(\w+)\b/;
        $self->{_deviceid} = $deviceid if $deviceid;
    }

    bless $self, $class;
    $self->init();

    return $self;
}

sub init {}

sub checking_error {}

sub host {
    my ($self, $hostname) = @_;

    $self->{_host} = $hostname if $hostname;

    return $self->{_host} // '';
}

sub mode {
    my ($self, $mode) = @_;

    return $self->{_mode} && $self->{_mode} eq $mode
        if $mode;

    return $self->{_mode} // '';
}

sub resetmode {
    my ($self) = @_;
    delete $self->{_mode};
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
            if ($info && $info->{addr}) {
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

    # Keep any specific variable
    map { $dump->{$_} = $self->{$_} } @{$self->{_keep_in_dump}};

    return $dump;
}

sub url {
    my ($self) = @_;

    return $self->{_url};
}

sub safe_url {
    my ($self) = @_;

    return $self->{_url} if $self->config && $self->config->{'show-passwords'};

    my $url = URI->new($self->{_url});
    return $self->{_url} unless $url->userinfo;
    my ($user, $pass) = split(/:/, $url->userinfo);
    $url->userinfo("$user:****");
    return $url->as_string;
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
