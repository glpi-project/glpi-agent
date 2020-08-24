package FusionInventory::Agent::Task::RemoteInventory::Remote;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use URI;
use Socket qw(getaddrinfo getnameinfo);

use FusionInventory::Agent::Tools::Network;

my $supported_protocols = qr/^ssh$/;

sub new {
    my ($class, %params) = @_;

    my $dump = $params{dump} // {};

    my $self = {
        _expiration => $dump->{expiration} // 0,
        _deviceid   => $dump->{deviceid}   // '',
        _url        => $dump->{url}        // $params{url},
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

    $self->{_protocol} = $scheme;
    $self->{_host} = $url->host;
    my $userinfo = $url->userinfo;
    if ($userinfo) {
        my ($user, $pass) = split(/:/, $userinfo);
        $self->{_user} = $user;
        $self->{_pass} = $pass if defined($pass);
    }

    # Check for mode in url params
    my $query = $url->query() // '';
    my ($mode) = $query =~ /mode=(\w+)/;
    $self->{_mode} = $mode if $mode;

    bless $self, $class;
    $self->init();

    return $self;
}

sub init {}

sub checked {}

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

        $hostname =~ s/\..*$//;

        my ($year, $month , $day, $hour, $min, $sec) = (localtime(time))[5, 4, 3, 2, 1, 0];

        $self->{_deviceid} = sprintf("$hostname-%02d-%02d-%02d-%02d-%02d-%02d",
            $year + 1900, $month + 1, $day, $hour, $min, $sec);
    }

    return $self->{_deviceid} // '';
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
