package GLPI::Agent::Task::RemoteInventory;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory';

use Parallel::ForkManager;

use GLPI::Agent::Tools;
use GLPI::Agent::Task::RemoteInventory::Remotes;

sub isEnabled {
    my ($self) = @_;

    # Always disable task unless target is server or local
    unless ($self->{target}->isType('server') || $self->{target}->isType('local')) {
        $self->{logger}->debug("Remote inventory task execution disabled: no supported target");
        return 0;
    }

    # Always enable remoteinventory task if remote option is set
    return 1 if $self->{config}->{remote};

    my $remotes = GLPI::Agent::Task::RemoteInventory::Remotes->new(
        config  => $self->{config},
        storage => $self->{target}->getStorage(),
        logger  => $self->{logger},
    );

    if ($remotes->count() && $remotes->next()) {
        $self->{logger}->debug("Remote inventory task execution enabled");
        return 1;
    }

    $self->{logger}->debug("Remote inventory task execution disabled: no remote setup");

    return 0;
}

sub run {
    my ($self, %params) = @_;

    my $remotes = GLPI::Agent::Task::RemoteInventory::Remotes->new(
        config  => $self->{config},
        storage => $self->{target}->getStorage(),
        logger  => $self->{logger},
    );

    my $worker_count = $remotes->count() > 1 ? $self->{config}->{'remote-workers'} : 0;

    my $start = time;

    my $manager = Parallel::ForkManager->new($worker_count);
    $manager->set_waitpid_blocking_sleep(0);

    if ($worker_count) {
        $manager->run_on_start(
            sub {
                my ($pid, $remote) = @_;
                my $worker = $remote->worker();
                $self->{logger}->debug("Starting remoteinventory worker[$worker] to handle ".$remote->safe_url());
            }
        );
    }

    $manager->run_on_finish(
        sub {
            my ($pid, $ret, $remote) = @_;
            my $remoteid = $remote->safe_url();
            my $worker = $remote->worker();
            if ($ret) {
                $self->{logger}->error("Remoteinventory worker[$worker] failed to handle $remoteid") if $worker_count;
                # We want to schedule a retry but limited by target max delay
                $remotes->retry($remote, $self->{target}->getMaxDelay());
            } else {
                $self->{logger}->debug("Remoteinventory worker[$worker] finished to handle $remoteid") if $worker_count;
                $remote->expiration($self->{target}->computeNextRunDate());
            }
            # Store new remotes scheduling if required
            $remotes->store();
        }
    );

    my $worker = 0;
    while (my $remote = $remotes->next()) {
        $remote->worker(++$worker) if $worker_count;
        $manager->start($remote) and next;

        $remote->prepare();

        my $error = $remote->checking_error();
        my $deviceid = $remote->deviceid;

        my $remoteid = $deviceid // $remote->safe_url();
        $self->{logger}->{prefix} = "[worker $worker] $remoteid, " if $worker_count;
        if ($error || !$deviceid) {
            $self->{logger}->debug("Skipping remote inventory task execution for $remoteid: $error");
            $manager->finish(1);
            # In the case we have only one remote, finish won't leave the loop, so always last here
            last;
        }

        $self->{deviceid} = $deviceid;

        # Set now we are remote
        $self->setRemote($remote->protocol());

        setRemoteForTools($remote);

        $self->SUPER::run(%params);

        $remote->disconnect();

        resetRemoteForTools();

        delete $self->{logger}->{prefix} if $worker_count;

        $manager->finish();
    }

    $manager->wait_all_children();

    my $timing = time - $start;
    $self->{logger}->debug("Remote inventory task run in $timing seconds");
}

1;
