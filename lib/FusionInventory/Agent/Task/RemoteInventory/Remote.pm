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

    bless $self, $class;
    $self->init();

    return $self;
}

sub init {}

sub host {
    my ($self) = @_;

    return $self->{_host} // '';
}

sub deviceid {
    my ($self) = @_;

    # TODO deviceid should be reset after the real hostname is known

    # If not defined, use same algorithm than in Inventory module
    unless ($self->{_deviceid}) {
        # Try to resolve address is host given as an ip
        my $hostname = $self->host();
        if ($hostname =~ $ip_address_pattern) {
            my $info = getaddrinfo($hostname);
            if ($info && $info->{addr}) {
                my ($err, $name) = getnameinfo($info->{addr});
                $name =~ s/\..*$// if $name;
                $hostname = $name if $name;
            }
        }

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

    return {
        deviceid    => $self->{_deviceid},
        url         => $self->{_url},
        protocol    => $self->{_protocol},
        expiration  => $self->{_expiration},
    };
}

sub url {
    my ($self) = @_;

    return $self->{_url};
}

1;
