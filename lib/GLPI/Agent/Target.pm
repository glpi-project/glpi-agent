package GLPI::Agent::Target;

use strict;
use warnings;

use English qw(-no_match_vars);

use GLPI::Agent::Logger;
use GLPI::Agent::Storage;

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

    $self->{storage} = GLPI::Agent::Storage->new(
        logger    => $self->{logger},
        directory => $params{vardir}
    );

    my $keepMaxDelay = $self->getMaxDelay();

    # handle persistent state
    $self->_loadState();

    # Update maxDelay from provided config when not a server
    unless ($self->isType('server')) {
        $self->setMaxDelay($keepMaxDelay);
    }

    $self->{nextRunDate} = $self->computeNextRunDate()
        if (!$self->{nextRunDate} || $self->{nextRunDate} < time-$self->getMaxDelay());

    $self->_saveState();

    $logger->debug(
        "[target $self->{id}] Next " .
        ($self->isType("server") ? "server contact" : "tasks run") .
        " planned " .
        ($self->{nextRunDate} < time ? "now" : "for ".localtime($self->{nextRunDate}))
    );

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
    $self->_saveState();

    # Remove initialDelay to support case we are still forced to run at start
    delete $self->{initialDelay};
}

sub resetNextRunDate {
    my ($self) = @_;

    # Don't reset next run date if still set via setNextRunOnExpiration
    return if delete $self->{_expiration};

    $self->{_nextrundelay} = 0;
    $self->{nextRunDate} = $self->computeNextRunDate();
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
        push @{$self->{_events}}, {
            name    => "init",
            task    => $task,
            init    => "yes",
            rundate => time+10,
        };
    }
}

sub addEvent {
    my ($self, $event) = @_;

    my $logger = $self->{logger};

    # Check for supported events
    my $partial = delete $event->{partial};
    if ($partial && $partial =~ /^yes|1$/i && defined($event->{category})) {
        unless ($event->{category}) {
            $logger->debug("[target $self->{id}] Not supported partial inventory request without selected category");
            return 0;
        }
        # Partial inventory request on given categories
        $event->{partial} = 1;
        $event->{task}    = "inventory";
        $event->{name}    = "partial inventory";
        $logger->debug("[target $self->{id}] Partial inventory event on category: $event->{category}");
        # Remove any existing partial inventory event
        $self->{_events} = [ grep { ! $_->{partial} } @{$self->{_events}} ]
            if $self->{_events} && @{$self->{_events}};
    } elsif ($event->{maintenance} && $event->{maintenance} =~ /^yes|1$/i) {
        my $debug = "[target $self->{id}] New $event->{name} event on $event->{task} task";
        my $count = 0;
        $count = @{$self->{_events}} if $self->{_events};
        if ($count) {
            # Remove any existing maintenance event for the same target
            $self->{_events} = [
                grep {
                    ! $_->{maintenance} || $_->{task} ne $event->{task} || $_->{target} ne $event->{target}
                } @{$self->{_events}}
            ];
            $debug = "[target $self->{id}] Replacing $event->{name} event on $event->{task} task"
                if @{$self->{_events}} < $count;
        }
        $logger->debug($debug);
    } else {
        $logger->debug("[target $self->{id}] Not supported event request: ".join("-",keys(%{$event})));
        return 0;
    }

    if (@{$self->{_events}}>20) {
        $logger->debug("[target $self->{id}] Event requests overflow, skipping new event");
        return 0;
    } elsif ($self->{_next_event}) {
        my $nexttime = $self->{_next_event}->{$event->{name}};
        if ($nexttime && time < $nexttime) {
            $logger->debug("[target $self->{id}] Skipping too early new $event->{name} event");
            return 0;
        }
        # Do not accept the same event in less than 15 seconds
        $self->{_next_event}->{$event->{name}} = time + 15;
    }

    my $delay = delete $event->{delay} // 0;
    $event->{rundate} = time + $delay;
    $logger->debug2("[target $self->{id}] Event scheduled in $delay seconds") if $delay;

    if ($self->{_events} && !@{$self->{_events}}) {
        push @{$self->{_events}}, $event;
    } else {
        $self->{_events} = [
            sort { $a->{rundate} <=> $b->{rundate} } @{$self->{_events}}, $event
        ];
    }

    return $event;
}

sub getEvent {
    my ($self) = @_;
    return unless @{$self->{_events}} && time >= $self->{_events}->[0]->{rundate};
    return shift @{$self->{_events}};
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

# compute a run date, as current date and a random delay
# between maxDelay / 2 and maxDelay
sub computeNextRunDate {
    my ($self) = @_;

    my $ret;
    if ($self->{initialDelay}) {
        $ret = time + ($self->{initialDelay} / 2) + int rand($self->{initialDelay} / 2);
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
        $ret = time + $self->{maxDelay} - int(rand($max_random_delay_reduc));
    }

    return $ret;
}

sub _loadState {
    my ($self) = @_;

    my $data = $self->{storage}->restore(name => 'target');

    map { $self->{$_} = $data->{$_} } grep { defined($data->{$_}) } qw/
        maxDelay nextRunDate id
    /;

    # Update us as GLPI server is recognized as so before
    $self->isGlpiServer(1) if $data->{is_glpi_server};
}

sub _saveState {
    my ($self) = @_;

    my $data ={
        maxDelay    => $self->{maxDelay},
        nextRunDate => $self->{nextRunDate},
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
