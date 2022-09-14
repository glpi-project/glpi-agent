package GLPI::Agent::Task::RemoteInventory::Remotes;

use strict;
use warnings;

use GLPI::Agent::Task::RemoteInventory::Remote;

sub new {
    my ($class, %params) = @_;

    die 'no storage parameter' unless $params{storage};

    my $self = {
        _config     => $params{config},
        _count      => 0,
        _remotes    => {},
        logger      => $params{logger},
    };
    bless $self, $class;

    # Handle remotes from --remote option or load them from storage
    if ($self->{_config}->{remote}) {
        foreach my $url (split(/,/, $self->{_config}->{remote})) {
            next unless $url;

            # Skip if url is still known for a remote
            next if grep { $_->url() eq $url } $self->getall();

            my $remote = GLPI::Agent::Task::RemoteInventory::Remote->new(
                url     => $url,
                config  => $self->{_config},
                logger  => $params{logger},
            );
            $remote->supported()
                or next;

            my $id = $remote->safe_url()
                or next;

            # Don't overwrite remote if still known
            next if $self->{_remotes}->{$id};
            $self->{_remotes}->{$id} = $remote;
            $self->{_count}++;
        }
    } else {
        # Keep storage if we need to store expiration
        $self->{_storage} = $params{storage};

        # Load remotes from storage
        my $remotes = $self->{_storage}->restore( name => 'remotes' ) // {};
        foreach my $id (keys(%{$remotes})) {
            my $dump = $remotes->{$id};
            next unless ref($dump) eq 'HASH';
            my $remote = GLPI::Agent::Task::RemoteInventory::Remote->new(
                dump    => $dump,
                config  => $self->{_config},
                logger  => $self->{logger},
            );
            next unless $remote->supported();
            $self->{_remotes}->{$id} = $remote;
            $self->{_count}++;
        }
    }

    return $self;
}

sub count {
    my ($self) = @_;
    return $self->{_count};
}

sub get {
    my ($self, $deviceid) = @_;

    return $self->{_remotes}->{$deviceid};
}

sub getlist {
    my ($self) = @_;

    return keys %{$self->{_remotes}};
}

sub getall {
    my ($self) = @_;

    return values %{$self->{_remotes}};
}

sub sort {
    my ($self) = @_;

    return unless $self->{_list} && @{$self->{_list}} > 1;

    $self->{_list} = [
        sort { $a->expiration() <=> $b->expiration() } @{$self->{_list}}
    ];
}

sub next {
    my ($self) = @_;

    # next API now always initialize an internal list
    unless ($self->{_list}) {
        my @remotes = $self->getall()
            or return;

        $self->{_list} = \@remotes;

        $self->sort();
    }

    my $remote = shift @{$self->{_list}}
        or return;

    # Skip scheduling check if forcing and not re-trying a failed remote
    unless ($self->{_config}->{force} && !$remote->retry()) {
        return if ($self->{_config}->{'remote-scheduling'} || $remote->retry()) && $remote->expiration() > time;
    }

    return $remote;
}

sub retry {
    my ($self, $remote, $maxdelay) = @_;

    return unless $self->{_list};

    # Add one hour to last retry time
    my $timeout = $remote->retry() // 0;
    $timeout += 3600;
    # But don't retry if the delay is overdue
    return if $timeout > $maxdelay;

    push @{$self->{_list}}, $remote->retry($timeout);

    # Always sort in case of a not empty big list running for a bigger time than
    # the retry expiration but not if forcing so retry always occurs after the
    # last pending remote
    $self->sort() unless $self->{_config}->{force};
}

sub store {
    my ($self) = @_;

    return unless $self->{_storage};

    my $remotes = {};

    foreach my $id (keys(%{$self->{_remotes}})) {
        my $dump = $self->{_remotes}->{$id}->dump()
            or next;
        $remotes->{$id} = $dump;
    }

    my $umask = umask 0007;
    $self->{_storage}->save( name => 'remotes', data => $remotes );
    umask $umask;
}

sub add {
    my ($self, $remote) = @_;

    return unless $remote && ref($remote) =~ /^GLPI::Agent::Task::RemoteInventory::Remote/;

    $self->{_remotes}->{$remote->deviceid()} = $remote;
    return $remote->deviceid();
}

sub del {
    my ($self, $deviceid) = @_;

    return unless $deviceid && exists($self->{_remotes}->{$deviceid});

    return delete $self->{_remotes}->{$deviceid};
}

1;
