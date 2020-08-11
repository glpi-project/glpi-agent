package FusionInventory::Agent::Task::RemoteInventory;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Task::RemoteInventory::Remotes;

sub isEnabled {
    my ($self, $response) = @_;

    my $remotes = FusionInventory::Agent::Task::RemoteInventory::Remotes->new(
        config  => $self->{config},
        storage => $self->{target}->getStorage(),
        logger  => $self->{logger},
    );

    my $remote = $remotes->next()
        or return;

    setRemoteForTools($remote);

    my $uname = getFirstLine(command => 'uname -a');

    resetRemoteForTools();

    $self->{logger}->debug("Remote inventory task execution disabled on uname test") unless $uname;

    return 0 unless $uname;

    # always enabled for local target
    return 1 if $self->{target}->isType('local');

    if ($self->{target}->isType('server') && $self->{config}->{remote}) {
        $self->{logger}->debug("Remote inventory task execution enabled");
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

    # Handle only one remote at a time
    my $remote = $remotes->next()
        or return;

    $self->{deviceid} = $remote->deviceid();

    # Set now we are remote
    $self->setRemote($remote->protocol());

    setRemoteForTools($remote);

    $self->SUPER::run(%params);

    resetRemoteForTools();

    # Set expiration from target for the remote before storing remotes
    $self->{target}->resetNextRunDate();
    $remote->expiration($self->{target}->getNextRunDate());
    $remotes->store();
}

1;
