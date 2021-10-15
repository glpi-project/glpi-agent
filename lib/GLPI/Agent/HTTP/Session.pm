package GLPI::Agent::HTTP::Session;

use strict;
use warnings;

use Digest::SHA;

use GLPI::Agent::Logger;

my $log_prefix = "[http session] ";

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger  => $params{logger} ||
                        GLPI::Agent::Logger->new(),
        timer   => $params{timer} || [ time, $params{timeout} || 600 ],
        nonce   => $params{nonce} || '',
        _sid    => $params{sid} || '',
        _info   => $params{infos} || '',
    };
    bless $self, $class;

    # Generate a random sid when not provided
    $self->{_sid} = join("-", map { unpack("h4", pack("I", int(rand(65536)))) } 1..4)
        unless $self->{_sid};

    # Include private params as datas
    foreach my $data (keys(%params)) {
        next unless $data =~ /^_(\w+)$/;
        $self->{datas}->{$1} = $params{$data};
    }

    return $self;
}

sub info {
    my $self = shift;

    $self->{_info} = join(" ; ", @_) if @_;

    my @infos = ($self->{_sid});
    push @infos, $self->{_info} if $self->{_info};
    my $expiration = localtime($self->{timer}[0] + $self->{timer}[1]);
    push @infos, "expiration on $expiration";

    return join(" ; ", @infos);
}

sub sid {
    my ($self) = @_;
    return $self->{_sid} || '';
}

sub expired {
    my ($self) = @_;

    return $self->{timer}[0] + $self->{timer}[1] < time
        if ref($self->{timer}) eq 'ARRAY';
}

sub nonce {
    my ($self) = @_;

    unless ($self->{nonce}) {
        my $sha = Digest::SHA->new(1);

        my $nonce;
        eval {
            for (my $i = 0; $i < 32; $i ++) {
                $sha->add(ord(rand(256)));
            }
            $nonce = $sha->b64digest;
        };

        $self->{logger}->debug($log_prefix . "Nonce failure: $@") if $@;

        $self->{nonce} = $nonce
            if $nonce;
    }

    return $self->{nonce};
}

sub authorized {
    my ($self, %params) = @_;

    return unless $params{token} && $params{payload};

    my $sha = Digest::SHA->new('256');

    my $digest;
    eval {
        $sha->add($self->{nonce}.'++'.$params{token});
        $digest = $sha->b64digest;
    };
    $self->{logger}->debug($log_prefix . "Digest failure: $@") if $@;

    return ($digest && $digest eq $params{payload});
}

sub dump {
    my ($self) = @_;

    my $dump = {};

    $dump->{nonce} = $self->{nonce} if $self->{nonce};
    $dump->{timer} = $self->{timer} if $self->{timer};
    $dump->{infos} = $self->{_info} if $self->{_info};
    if ($self->{datas}) {
        foreach my $data (keys(%{$self->{datas}})) {
            $dump->{"_$data"} = $self->{datas}->{$data};
        }
    }

    return $dump;
}

sub set {
    my ($self, $data, $value) = @_;

    # Update session time
    $self->{timer}->[0] = time;

    return unless $data;

    $self->{datas}->{$data} = defined($value) ? $value : "";
}

sub get {
    my ($self, $data) = @_;

    # Update session time
    $self->{timer}->[0] = time;

    return unless $data && $self->{datas};

    return $self->{datas}->{$data};
}

sub delete {
    my ($self, $data) = @_;

    # Update session time
    $self->{timer}->[0] = time;

    return unless $data && $self->{datas};

    delete $self->{datas}->{$data};
}

sub keep {
    my ($self, $data, $value) = @_;

    return unless $data;

    $self->{_keep}->{$data} = defined($value) ? $value : "";
}

sub kept {
    my ($self, $data) = @_;

    return unless $data && $self->{_keep};

    return $self->{_keep}->{$data};
}

sub forget {
    my ($self, $data) = @_;

    return unless $data && $self->{_keep};

    delete $self->{_keep}->{$data};
}

1;

__END__

=head1 NAME

GLPI::Agent::HTTP::Session - An abstract HTTP session

=head1 DESCRIPTION

This is an abstract class for HTTP sessions. It can be used to store
peer connection status.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<timer>

the initial timer used when restoring a session from storage

=item I<nonce>

the nonce used to compute the final secret when restoring a session from storage

=item I<timeout>

the session timeout for session expiration (default to 60, in seconds)

=back

=head2 authorized()

Return true if provided secret matches the token.

=head2 expired()

Return true when a session expired.

=head2 nonce()

Return session nonce creating one if not available.

=head2 dump()

Return session hash to be stored for session persistence.

=head2 info(@infos)

First store @infos in session datas.

Then returns them in an info string including sid and expiration time.

=head2 sid()

Return session sid.

=head2 set($data, $value)

Store $value in session datas as $data data.

=head2 get($data)

Return $data data as it is stored in session datas.

=head2 delete($data)

Delete $data data from stored session datas.

=head2 keep($data, $value)

Keep $value as $data value in memory so it won't be exported by dump() call.

=head2 kept($data)

Return $data data kept in memory.

=head2 forget($data)

Forget $data data kept in memory.
