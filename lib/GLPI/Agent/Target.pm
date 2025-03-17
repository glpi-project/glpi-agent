package GLPI::Agent::Target;

use strict;
use warnings;

use English qw(-no_match_vars);

use GLPI::Agent::Logger;
use GLPI::Agent::Storage;
use GLPI::Agent::Event;

my $errMaxDelay = 0;

sub new {
    my ($class, %params) = @_;

    die "no basevardir parameter for target\n" unless $params{basevardir};

    # errMaxDelay is the maximum delay on network error. Delay on network error starts
    # from 60, is doubled at each new failed attempt until reaching delaytime.
    # Take the first provided delaytime for the agent lifetime
    unless ($errMaxDelay) {
        $errMaxDelay = $params{delaytime} || 3600;
    }

    my $self = {
        logger       => $params{logger} ||
                        GLPI::Agent::Logger->new(),
        maxDelay     => $params{maxDelay} || 3600,
        errMaxDelay  => $errMaxDelay,
        initialDelay => $params{delaytime},
        _glpi        => $params{glpi} // '',
        _events      => [],
        _next_event  => {},
    };
    bless $self, $class;

    return $self;
}

sub _init {
    my ($self, %params) = @_;

    my $logger = $self->{logger};

    # target identity
    $self->{id} = $params{id};

    # Initialize logger prefix
    $self->{_logprefix} = "[target $self->{id}]";

    $self->{storage} = GLPI::Agent::Storage->new(
        logger    => $self->{logger},
        oldvardir => $params{oldvardir} // "",
        directory => $params{vardir}
    );

    my $keepMaxDelay = $self->getMaxDelay();

    # handle persistent state
    $self->_loadState();

    # Update maxDelay from provided config when not a server
    unless ($self->isType('server')) {
        $self->setMaxDelay($keepMaxDelay);
    }

    # Disable initialDelay if next run date has still been set in a previous run and was planified in the last max delay
    my $lastExpectedRunDateLimit = time-$self->getMaxDelay();
    delete $self->{initialDelay} if $self->{initialDelay} && $self->{nextRunDate} && $self->{nextRunDate} >= $lastExpectedRunDateLimit;

    # Setup targeted run date if necessary
    $self->{baseRunDate} = time + ($self->{initialDelay} // $self->getMaxDelay())
        unless $self->{baseRunDate} && $self->{baseRunDate} > $lastExpectedRunDateLimit;

    # Set next run date in the future unless still set and in the expected last run limit
    $self->{nextRunDate} = $self->computeNextRunDate()
        unless $self->{nextRunDate} && $self->{nextRunDate} >= $lastExpectedRunDateLimit;

    $self->_saveState();

    $logger->debug(
        "$self->{_logprefix} Next " .
        ($self->isType("server") ? "server contact" : "tasks run") .
        " planned " .
        ($self->{nextRunDate} < time ? "now" : "for ".localtime($self->{nextRunDate}))
    ) if $self->{initialDelay};

    # Disable initialDelay if next run date has still been set in a previous run to a later time
    delete $self->{initialDelay} if $self->{initialDelay} && $self->{nextRunDate} && $self->{nextRunDate} > time;
}

sub id {
    my ($self) = @_;

    return $self->{id};
}

sub getStorage {
    my ($self) = @_;

    return $self->{storage};
}

sub setNextRunOnExpiration {
    my ($self, $expiration) = @_;

    $self->{nextRunDate} = time + ($expiration // 0);
    $self->{baseRunDate} = $self->{nextRunDate};
    $self->_saveState();

    # Be sure to skip next resetNextRunDate() call
    $self->{_expiration} = $expiration;
}

sub setNextRunDateFromNow {
    my ($self, $nextRunDelay) = @_;

    if ($nextRunDelay) {
        # While using nextRunDelay, we double it on each consecutive call until
        # delay reach target defined maxDelay. This is only used on network failure.
        $nextRunDelay = 2 * $self->{_nextrundelay} if ($self->{_nextrundelay});
        $nextRunDelay = $self->getMaxDelay() if ($nextRunDelay > $self->getMaxDelay());
        # Also limit toward the initial delaytime as it is also used to
        # define the maximum delay on network error
        $nextRunDelay = $self->{errMaxDelay} if ($nextRunDelay > $self->{errMaxDelay});
        $self->{_nextrundelay} = $nextRunDelay;
    }
    $self->{nextRunDate} = time + ($nextRunDelay // 0);
    $self->{baseRunDate} = $self->{nextRunDate};
    $self->_saveState();

    # Remove initialDelay to support case we are still forced to run at start
    delete $self->{initialDelay};
}

sub resetNextRunDate {
    my ($self) = @_;

    # Don't reset next run date if still set via setNextRunOnExpiration
    return if delete $self->{_expiration};

    my $timeref = $self->{baseRunDate} || time;

    # Reset timeref if out of range defined by maxDelay
    $timeref = time if $timeref < time - $self->getMaxDelay() || $timeref > time + $self->getMaxDelay();

    $self->{_nextrundelay} = 0;
    $self->{nextRunDate} = $self->computeNextRunDate($timeref);
    $self->{baseRunDate} = $timeref + $self->getMaxDelay();
    $self->_saveState();
}

sub getNextRunDate {
    my ($self) = @_;

    # Check if state file has been updated by a third party, like a script run
    $self->_loadState() if $self->_needToReloadState();

    return $self->{nextRunDate};
}

sub triggerTaskInitEvents {
    my ($self) = @_;

    return unless $self->{tasks} && @{$self->{tasks}};

    foreach my $task (@{$self->{tasks}}) {
        push @{$self->{_events}}, GLPI::Agent::Event->new(
            task    => $task,
            init    => "yes",
            rundate => time+10,
        );
    }
}

sub triggerRunTasksNow {
    my ($self, $event) = @_;

    # $tasks must be set to "all" to trigger all tasks
    return unless $event && $event->runnow && $self->{tasks} && @{$self->{tasks}};

    my %plannedTasks = map { lc($_) => 1 } @{$self->{tasks}};
    my $task = $event->task;
    my $all = $task && $task eq "all" ? 1 : 0;
    my @tasks = $all ? @{$self->{tasks}} : split(/,+/, $task);
    my $reschedule_index = $all ? scalar(@tasks) : 0;
    foreach my $runtask (map { lc($_) } @tasks) {
        $reschedule_index--;
        next unless $plannedTasks{$runtask};

        my %event = (
            taskrun => 1,
            task    => $runtask,
            # runnow event can still have been delayed itself
            delay   => 0,
        );

        # permit to reschedule on last task run
        $event{reschedule} = 1
            if $all && $reschedule_index == 0;

        # Add any supported params
        if ($runtask eq "inventory") {
            my $full    = $event->get("full");
            my $partial = $event->get("partial");
            if (defined($full)) {
                $event{"full"} = $full;
            } elsif (defined($partial)) {
                $event{"partial"} = $partial;
            } else {
                $event{"full"} = 1;
            }
        }

        $self->addEvent(GLPI::Agent::Event->new(%event), 1);
    }

    # Also reset cached responses
    delete $self->{_responses};
}

sub addEvent {
    my ($self, $event, $safe) = @_;

    # event name is mandatory
    return unless $event && $event->name;

    my $logger = $self->{logger};
    my $logprefix = $self->{_logprefix};

    # Check for supported events
    if (!$event->job && ($event->runnow || $event->taskrun)) {
        unless ($event->task) {
            $logger->debug("$logprefix Not supported ".$event->name." event without task");
            return 0;
        }
        $logger->debug("$logprefix Adding ".$event->name." event for ".$event->task." task".
            ($event->task ne "all" && $event->task !~ /,/ ? "" : "s")
        );
    } elsif ($event->partial) {
        unless ($event->category) {
            $logger->debug("$logprefix Not supported partial inventory request without selected category");
            return 0;
        }
        $logger->debug("$logprefix Partial inventory event on category: ".$event->category);
        # Remove any existing partial inventory event
        $self->{_events} = [ grep { ! $_->partial } @{$self->{_events}} ]
            if $self->{_events} && @{$self->{_events}};
    } elsif ($event->maintenance) {
        unless ($event->task) {
            $logger->debug("$logprefix Not supported maintenance request without selected task");
            return 0;
        }
        my $debug = "New";
        if ($self->{_events}) {
            my $count = @{$self->{_events}};
            # Remove any existing maintenance event for the same target
            $self->{_events} = [
                grep {
                    ! $_->maintenance || $_->task ne $event->task || $_->target ne $event->target
                } @{$self->{_events}}
            ];
            $debug = "Replacing" if @{$self->{_events}} < $count;
        }
        $logger->debug(sprintf("%s %s %s event on %s task", $logprefix, $debug, $event->name, $event->task));
    } elsif ($event->job) {
        my $rundate = $event->rundate;
        if ($rundate) {
            $logger->debug(sprintf("%s Adding %s job event as %s task scheduled on %s", $logprefix, $event->name, $event->task, scalar(localtime($rundate))));
        } else {
            $logger->debug(sprintf("%s Adding %s job event as %s task", $logprefix, $event->name, $event->task));
        }
    } else {
        $logger->debug("$logprefix Not supported event request: ".$event->dump_as_string());
        return 0;
    }

    if (@{$self->{_events}} >= 1024) {
        $logger->debug("$logprefix Event requests overflow, skipping new event");
        return 0;
    } elsif ($self->{_next_event} && !$safe) {
        my $nexttime = $self->{_next_event}->{$event->name};
        if ($nexttime && time < $nexttime) {
            $logger->debug("$logprefix Skipping too early new ".$event->name()." event");
            return 0;
        }
        # Do not accept the same event in less than 15 seconds
        $self->{_next_event}->{$event->name} = time + 15;
    }

    # Job should still have rundate set
    unless ($event->job) {
        my $delay = $event->delay() // 0;
        $event->rundate(time + $delay);
        $logger->debug2("$logprefix Event scheduled in $delay seconds") if $delay;
    }

    if (!$self->{_events} || !@{$self->{_events}} || $event->rundate > $self->{_events}->[-1]->rundate) {
        push @{$self->{_events}}, $event;
    } else {
        $self->{_events} = [
            sort { $a->rundate <=> $b->rundate } @{$self->{_events}}, $event
        ];
    }

    return $event;
}

sub delEvent {
    my ($self, $event) = @_;

    return unless $event->name;

    # Always accept new event for this name
    delete $self->{_next_event}->{$event->name}
        if $self->{_next_event};

    # Cleanup event list
    $self->{_events} = [ grep { $_->name ne $event->name || (($event->init || $event->maintenance || $event->taskrun) && $_->task ne $event->task) } @{$self->{_events}} ];
}

sub nextEvent {
    my ($self) = @_;

    return unless @{$self->{_events}} && time >= $self->{_events}->[0]->rundate;

    return $self->{_events}->[0];
}

sub paused {
    my ($self) = @_;

    return $self->{_paused} || 0;
}

sub pause {
    my ($self) = @_;

    $self->{_paused} = 1;
}

sub continue {
    my ($self) = @_;

    delete $self->{_paused};
}

sub getFormatedNextRunDate {
    my ($self) = @_;

    return $self->{nextRunDate} > 1 ?
        scalar localtime($self->{nextRunDate}) : "now";
}

sub getMaxDelay {
    my ($self) = @_;

    return $self->{maxDelay};
}

sub setMaxDelay {
    my ($self, $maxDelay) = @_;

    $self->{maxDelay} = $maxDelay;
    $self->_saveState();
}

sub isType {
    my ($self, $testtype) = @_;

    return unless $testtype;

    my $type = $self->getType()
        or return;

    return "$type" eq "$testtype";
}

sub isGlpiServer {
    return 0;
}

# Compute a run date from time ref reduced from a little random delay
sub computeNextRunDate {
    my ($self, $timeref) = @_;

    $timeref = time unless $timeref;

    if ($self->{initialDelay}) {
        $timeref += $self->{initialDelay} - int(rand($self->{initialDelay}/2));
        delete $self->{initialDelay};
    } else {
        # By default, reduce randomly the delay by 0 to 3600 seconds (1 hour max)
        my $max_random_delay_reduc = 3600;
        # For delays until 6 hours, reduce randomly the delay by 10 minutes for each hour: 600*(T/3600) = T/6
        if ($self->{maxDelay} < 21600) {
            $max_random_delay_reduc = $self->{maxDelay} / 6;
        } elsif ($self->{maxDelay} > 86400) {
            # Finally reduce randomly the delay by 1 hour for each 24 hours, for delay other than a day
            $max_random_delay_reduc = $self->{maxDelay} / 24;
        }
        $timeref += $self->{maxDelay} - int(rand($max_random_delay_reduc));
    }

    return $timeref;
}

sub _loadState {
    my ($self) = @_;

    my $data = $self->{storage}->restore(name => 'target');

    map { $self->{$_} = $data->{$_} } grep { defined($data->{$_}) } qw/
        maxDelay nextRunDate id baseRunDate
    /;

    # Update us as GLPI server is recognized as so before
    $self->isGlpiServer(1) if $data->{is_glpi_server};
}

sub _saveState {
    my ($self) = @_;

    my $data ={
        maxDelay    => $self->{maxDelay},
        nextRunDate => $self->{nextRunDate},
        baseRunDate => $self->{baseRunDate},
        type        => $self->getType(),                 # needed by glpi-remote
        id          => $self->id(),                      # needed by glpi-remote
    };

    if ($self->isType('server')) {
        # Add a flag if we are a GLPI server target
        $data->{is_glpi_server} = 1 if $self->isGlpiServer();
        my $url = $self->getUrl();
        if (ref($url) =~ /^URI/) {
            $data->{url} = $url->as_string;              # needed by glpi-remote
        }
    } elsif ($self->isType('local')) {
        $data->{path} = $self->getPath();                # needed by glpi-remote
    }

    $self->{storage}->save(
        name => 'target',
        data => $data,
    );
}

sub _needToReloadState {
    my ($self) = @_;

    # Only re-check if it's time to reload after 30 seconds
    return if $self->{_next_reload_check} && time < $self->{_next_reload_check};

    $self->{_next_reload_check} = time+30;

    return $self->{storage}->modified(name => 'target');
}

sub getTaskVersion {
    my ($self) = @_;

    return $self->{_glpi};
}

sub responses {
    my ($self, $responses) = @_;
    return $self->{_responses} unless defined($responses);
    $self->{_responses} = $responses;
}

1;
__END__

=head1 NAME

GLPI::Agent::Target - Abstract target

=head1 DESCRIPTION

This is an abstract class for execution targets.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use

=item I<maxDelay>

the maximum delay before contacting the target, in seconds
(default: 3600)

=item I<basevardir>

the base directory of the storage area (mandatory)

=back

=head2 getNextRunDate()

Get nextRunDate attribute.

=head2 getFormatedNextRunDate()

Get nextRunDate attribute as a formated string.

=head2 setNextRunDateFromNow($nextRunDelay)

Set next execution date from now and after $nextRunDelay seconds (0 by default).

=head2 resetNextRunDate()

Set next execution date to a random value.

=head2 getMaxDelay($maxDelay)

Get maxDelay attribute.

=head2 setMaxDelay($maxDelay)

Set maxDelay attribute.

=head2 getStorage()

Return the storage object for this target.
