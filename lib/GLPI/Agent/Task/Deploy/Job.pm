package GLPI::Agent::Task::Deploy::Job;

use strict;
use warnings;

use English qw(-no_match_vars);

use GLPI::Agent::Task::Deploy::UserCheck;
use GLPI::Agent::Task::Deploy::CheckProcessor;

sub new {
    my ($class, %params) = @_;

    my $self = {
        _remoteUrl      => $params{remoteUrl},
        _client         => $params{client},
        _machineid      => $params{machineid},
        _currentStep    => 'init',
        logger          => $params{logger},
        uuid            => $params{data}->{uuid},
        requires        => $params{data}->{requires},
        checks          => $params{data}->{checks},
        userchecks      => $params{data}->{userinteractions},
        actions         => $params{data}->{actions},
        associatedFiles => $params{associatedFiles}
    };

    bless $self, $class;

    return $self;
}

sub getNextToProcess {
    my ($self) = @_;

    return unless $self->{actions};

    shift @{$self->{actions}};
}

sub currentStep {
    my ($self, $step) = @_;
    return $self->{_currentStep} = $step eq 'end' ? '' : $step;
}

sub setStatus {
    my ($self, %params) = @_;

    return unless $self->{_remoteUrl};

    # Base action hash we wan't to send back to server as job status
    my $action ={
        action      => "setStatus",
        machineid   => $self->{_machineid},
        part        => 'job',
        uuid        => $self->{uuid},
    };

    # Specific case where we want to send a file status
    if (exists($params{file}) && $params{file}) {
        $action->{part}   = 'file';
        $action->{sha512} = $params{file}->{sha512};
    }

    # Map other optional and set params to action
    map { $action->{$_} = $params{$_} }
        grep { exists($params{$_}) && $params{$_} } qw(
            status actionnum checknum msg
    );

    # Include currentStep if defined
    $action->{currentStep} = $self->{_currentStep} if $self->{_currentStep};

    # Send back the job status
    $self->{_client}->send(
        url  => $self->{_remoteUrl},
        args => $action
    );
}

sub skip_on_check_failure {
    my ($self, %params) = @_;

    my $logger = $self->{logger};
    my $checks = $params{checks} || $self->{checks};
    my $level  = $params{level} || 'job';

    if ( ref( $checks ) eq 'ARRAY' ) {
        my $checknum = 0;
        while ( @{$checks} ) {
            $checknum ++;

            my $check = shift @{$checks}
                or next;
            my $type = $check->{type} || 'unsupported';

            # Bless check object as CheckProcessor
            GLPI::Agent::Task::Deploy::CheckProcessor->new(
                check  => $check,
                logger => $logger,
            );

            my $name = $check->name();
            my $checkStatus = $check->process();

            if ($checkStatus =~ /^abort|error|ko|skip|startnow$/) {
                $logger->info("Skipping $level because $name check #$checknum failed") if $logger;

                if ($check->is("skip")) {
                    $self->setStatus(
                        status   => 'ok',
                        msg      => "check #$checknum, $name not successful then skip $level",
                        checknum => $checknum-1
                    );

                    $self->setStatus(
                        status   => 'ok',
                        msg      => "$level skipped",
                    );
                } elsif ($check->is("startnow")) {
                    $self->setStatus(
                        status   => 'ok',
                        msg      => "check #$checknum, $name not successful then start $level now",
                        checknum => $checknum-1
                    );

                    $self->setStatus(
                        status   => 'ok',
                        msg      => "$level started now",
                    );
                    # Shortcut other checks telling the job is not to be skipped
                    return 0;
                } else {
                    $self->setStatus(
                        status   => 'ko',
                        msg      => "check #$checknum, failure on $name, " . $check->message(),
                        checknum => $checknum-1
                    );
                }

                return 1;
            }

            my $info = $check->is() . ", " . $check->message();
            $logger->debug("check #$checknum: $name, got $checkStatus, $info") if $logger;
            if ( ($check->is("warning") || $check->is("info")) && $checkStatus ne 'ok' ) {
                $self->setStatus(
                    status   => $checkStatus,
                    msg      => "check #$checknum, $name $info",
                    checknum => $checknum-1
                );
            } else {
                $self->setStatus(
                    status   => $checkStatus,
                    msg      => "check #$checknum, $name passed",
                    checknum => $checknum-1
                );
            }
        }
    }

    return 0;
}

sub next_on_usercheck {
    my ($self, %params) = @_;

    my $logger = $self->{logger};
    my $checks = $params{userchecks} || $self->{userchecks};
    my $type   = $params{type} || 'after';

    return 0 unless $checks;
    unless (ref($checks) eq 'ARRAY') {
        $logger->debug("usercheck $type: unexpected usercheck request") if $logger;
        return 0;
    }

    # Server is meant to only request one usercheck of supported type: before|after
    my @checks = grep { $_->{type} && $_->{type} eq $type } @{$checks} ;
    unless (@checks) {
        $logger->debug2("usercheck $type: no user interaction requested") if $logger;
        return 0;
    }

    while ( @checks ) {
        my $check = GLPI::Agent::Task::Deploy::UserCheck->new(
            check  => shift @checks,
            logger => $logger
        );

        next unless $check;

        # Warning: Agent may wait here for user response
        $check->tell_users();

        # Report collected user events to server
        foreach my $event ($check->getEvents()) {
            $self->setUserEvent($event);
        }

        return 1 if ($check->stopped());
    }

    return 0;
}

sub setUserEvent {
    my ($self, $userevent) = @_;

    return unless $self->{_remoteUrl};

    # Base userevent hash we wan't to send back to server as job status
    my $action = {
        action      => "setUserEvent",
        machineid   => $self->{_machineid},
        part        => 'job',
        uuid        => $self->{uuid},
    };

    # Map interesting user event parameters
    map { $action->{$_} = $userevent->{$_} }
        grep { exists($userevent->{$_}) && $userevent->{$_} }
            qw( type behavior event user );

    # Include currentStep if defined
    $action->{currentStep} = $self->{_currentStep} if $self->{_currentStep};

    # Send back the job status
    $self->{_client}->send(
        url  => $self->{_remoteUrl},
        args => $action
    );
}

1;
