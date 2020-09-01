package FusionInventory::Agent::Task::RemoteInventory;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Task::RemoteInventory::Remotes;

sub isEnabled {
    my ($self, $response) = @_;

    # Always disable task unless target is server or local
    unless ($self->{target}->isType('server') || $self->{target}->isType('local')) {
        $self->{logger}->debug("Remote inventory task execution disabled");
        return 0;
    }

    my $remotes = FusionInventory::Agent::Task::RemoteInventory::Remotes->new(
        config  => $self->{config},
        storage => $self->{target}->getStorage(),
        logger  => $self->{logger},
    );

    while ($remotes->next()) {
        my $error = $remote->checking_error();
        if ($error) {
            my $deviceid = $remote->deviceid
                or next;
            $self->{logger}->debug("Skipping remote inventory task execution for $deviceid: $error");
            $remote->expiration($self->{target}->getNextRunDate());
            $remotes->store();
            next;
        }
        last;
    }

    if ($remotes->count()) {
        $self->{logger}->debug("Remote inventory task execution enabled");
        return 1;
    }

    $self->{logger}->debug("Remote inventory task execution disabled");

    return 0;
}

sub run {
    my ($self, %params) = @_;

    my $remotes = FusionInventory::Agent::Task::RemoteInventory::Remotes->new(
        config  => $self->{config},
        storage => $self->{target}->getStorage(),
        logger  => $self->{logger},
    );

    # Handle only one reachable remote at a time
    my $remote;
    while ($remote = $remotes->next()) {
        my $error = $remote->checking_error();
        last unless $error
        my $deviceid = $remote->deviceid
            or next;
        $self->{logger}->debug("Skipping remote inventory task execution for $deviceid: $error");
        # We want to retry in a hour
        $self->{target}->setNextRunDateFromNow(3600);
        $remote->expiration($self->{target}->getNextRunDate());
        $remotes->store();
    }
    return unless $remote

    my $start = time;

    $self->{deviceid} = $remote->deviceid();

    # Set now we are remote
    $self->setRemote($remote->protocol());

    setRemoteForTools($remote);

    $self->SUPER::run(%params);

    resetRemoteForTools();

    my $timing = time - $start;
    $self->{logger}->debug("Remote inventory run in $timing seconds");

    # Set expiration from target for the remote before storing remotes
    $self->{target}->resetNextRunDate();
    $remote->expiration($self->{target}->getNextRunDate());
    $remotes->store();
}

1;
