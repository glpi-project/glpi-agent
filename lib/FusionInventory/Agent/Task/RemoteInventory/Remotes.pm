package FusionInventory::Agent::Task::RemoteInventory::Remotes;

use strict;
use warnings;

use FusionInventory::Agent::Task::RemoteInventory::Remote;

sub new {
    my ($class, %params) = @_;

    die 'no storage parameter' unless $params{storage};

    my $self = {
        _config     => $params{config},
        _storage    => $params{storage},
        _remotes    => {},
        logger      => $params{logger},
    };
    bless $self, $class;

    # Load remotes from storage
    my $remotes = $self->{_storage}->restore( name => 'remotes' ) // {};
    foreach my $id (keys(%{$remotes})) {
        my $dump = $remotes->{$id};
        next unless ref($dump) eq 'HASH';
        $self->{_remotes}->{$id} = FusionInventory::Agent::Task::RemoteInventory::Remote->new(
            dump    => $dump,
            config  => $self->{_config},
            logger  => $self->{logger},
        );
    }

    if ($self->{_config}->{remote}) {
        my $updated = 0;
        foreach my $url (split(/,/, $self->{_config}->{remote})) {
            next unless $url;

            # Skip if url is still known for a remote
            next if grep { $_->url() eq $url } values(%{$self->{_remotes}});

            my $remote = FusionInventory::Agent::Task::RemoteInventory::Remote->new(
                url     => $url,
                config  => $self->{_config},
                logger  => $params{logger},
            ) or next;

            # Always check the remote so deviceid can also be defined on first access
            next if $remote->checking_error();

            my $id = $remote->deviceid()
                or next;

            # Don't overwrite remote if still known
            next if $self->{_remotes}->{$id};
            $self->{_remotes}->{$id} = $remote;
            $updated ++;
        }
        $self->store() if $updated;
    }

    return $self;
}

sub next {
    my ($self) = @_;

    my @remotes = values %{$self->{_remotes}}
        or return;

    my ($remote) = sort { $a->expiration() <=> $b->expiration() } @remotes;

    return unless $remote->expiration() <= time || $self->{_config}->{force};

    return $remote;
}

sub store {
    my ($self) = @_;

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

1;
