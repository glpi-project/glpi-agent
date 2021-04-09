package FusionInventory::Agent::Target;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Logger;
use FusionInventory::Agent::Storage;

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
                        FusionInventory::Agent::Logger->new(),
        maxDelay     => $params{maxDelay} || 3600,
        errMaxDelay  => $errMaxDelay,
        initialDelay => $params{delaytime},
    };
    bless $self, $class;

    return $self;
}

sub _init {
    my ($self, %params) = @_;

    my $logger = $self->{logger};

    # target identity
    $self->{id} = $params{id};

    $self->{storage} = FusionInventory::Agent::Storage->new(
        logger    => $self->{logger},
        directory => $params{vardir}
    );

    # handle persistent state
    $self->_loadState();

    $self->{nextRunDate} = $self->_computeNextRunDate()
        if (!$self->{nextRunDate} || $self->{nextRunDate} < time-$self->getMaxDelay());

    $self->_saveState();

    $logger->debug(
        "[target $self->{id}] Next server contact planned for " .
        localtime($self->{nextRunDate})
    );

}

sub getStorage {
    my ($self) = @_;

    return $self->{storage};
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
    $self->{nextRunDate} = time + ($nextRunDelay || 0);
    $self->_saveState();

    # Remove initialDelay to support case we are still forced to run at start
    $self->{initialDelay} = undef;
}

sub resetNextRunDate {
    my ($self) = @_;

    $self->{_nextrundelay} = 0;
    $self->{nextRunDate} = $self->_computeNextRunDate();
    $self->_saveState();
}

sub getNextRunDate {
    my ($self) = @_;

    # Check if state file has been updated by a third party, like a script run
    $self->_loadState() if $self->_needToReloadState();

    return $self->{nextRunDate};
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
sub _computeNextRunDate {
    my ($self) = @_;

    my $ret;
    if ($self->{initialDelay}) {
        $ret = time + ($self->{initialDelay} / 2) + int rand($self->{initialDelay} / 2);
        $self->{initialDelay} = undef;
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

    $self->{maxDelay}    = $data->{maxDelay}    if $data->{maxDelay};
    $self->{nextRunDate} = $data->{nextRunDate} if $data->{nextRunDate};
    $self->{_type}       = $data->{_type}       if $data->{_type};
}

sub _saveState {
    my ($self) = @_;

    my $data ={
        maxDelay    => $self->{maxDelay},
        nextRunDate => $self->{nextRunDate},
    };

    $data->{_type} = $self->{_type} if defined($self->{_type});

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

FusionInventory::Agent::Target - Abstract target

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
