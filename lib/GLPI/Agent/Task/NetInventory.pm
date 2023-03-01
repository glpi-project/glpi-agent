package GLPI::Agent::Task::NetInventory;

use strict;
use warnings;
use threads;
use parent 'GLPI::Agent::Task';

use English qw(-no_match_vars);
use Time::HiRes qw(usleep);
use Thread::Queue v2.01;
use UNIVERSAL::require;

use GLPI::Agent::XML::Query;
use GLPI::Agent::Version;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Hardware;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Expiration;
use GLPI::Agent::HTTP::Client::OCS;

use GLPI::Agent::Task::NetInventory::Version;
use GLPI::Agent::Task::NetInventory::Job;

our $VERSION = GLPI::Agent::Task::NetInventory::Version::VERSION;

sub isEnabled {
    my ($self, $contact) = @_;

    if (!$self->{target}->isType('server')) {
        $self->{logger}->debug("NetInventory task not compatible with local target");
        return;
    }

    if (ref($contact) ne 'GLPI::Agent::XML::Response') {
        # TODO Support NetInventory task via GLPI Agent Protocol
        $self->{logger}->debug("NetInventory task not supported by server");
        return;
    }

    my @options = $contact->getOptionsInfoByName('SNMPQUERY');
    if (!@options) {
        $self->{logger}->debug("NetInventory task execution not requested");
        return;
    }

    my @jobs;
    # Parse and validate options
    foreach my $option (@options) {

        next unless ref($option) eq 'HASH';

        unless (ref($option->{DEVICE}) eq 'ARRAY') {
            $self->{logger}->error("invalid job: no device defined");
            next;
        }

        my @devices;
        foreach my $device (@{$option->{DEVICE}}) {
            unless (ref($device) eq 'HASH') {
                $self->{logger}->error("invalid device found");
                next;
            }
            if (!$device->{IP}) {
                $self->{logger}->error("invalid device: no address defined");
                next;
            }
            push @devices, $device;
        }

        if (!@devices) {
            $self->{logger}->error("invalid job: no valid device defined");
            next;
        }

        unless (ref($option->{PARAM}) eq 'ARRAY') {
            $self->{logger}->error("invalid job: no valid param defined");
            next;
        }

        my $params = $option->{PARAM}->[0];

        unless (ref($params) eq 'HASH') {
            $self->{logger}->error("invalid job: invalid param defined");
            next;
        }

        push @jobs, GLPI::Agent::Task::NetInventory::Job->new(
            logger      => $self->{logger},
            params      => $params,
            credentials => $option->{AUTHENTICATION},
            devices     => \@devices
        );
    }

    if (!@jobs) {
        $self->{logger}->error("no valid job found, aborting");
        return;
    }

    $self->{jobs} = \@jobs;

    return 1;
}

sub _inventory_thread {
    my ($self, $jobs, $done) = @_;

    my $id = threads->tid();
    $self->{logger}->debug("[thread $id] creation");

    # run as long as they are a job to process
    while (my $job = $jobs->dequeue()) {

        last unless ref($job) eq 'HASH';
        last if $job->{leave};

        my $device = $job->{device};

        my $result;
        eval {
            $result = $self->_queryDevice($job);
        };
        if ($EVAL_ERROR) {
            chomp $EVAL_ERROR;
            $result = {
                ERROR => {
                    ID      => $device->{ID},
                    MESSAGE => $EVAL_ERROR
                }
            };

            $result->{ERROR}->{TYPE} = $device->{TYPE} if $device->{TYPE};

            # Inserted back device PID in result if set by server
            $result->{PID} = $device->{PID} if defined($device->{PID});

            $self->{logger}->error("[thread $id] $EVAL_ERROR");
        }

        # Get result PID from result
        my $pid = delete $result->{PID};

        # Directly send the result message from the thread, but use job pid if
        # it was not set in result
        $self->_sendResultMessage($result, $pid || $job->{pid});

        $done->enqueue($job);
    }

    delete $self->{logger}->{prefix};

    $self->{logger}->debug("[thread $id] termination");
}

sub run {
    my ($self, %params) = @_;

    # Extract greatest max_threads from jobs
    my ($max_threads) = sort { $b <=> $a } map { int($_->max_threads()) }
        @{$self->{jobs}};

    my %running_threads = ();

    # initialize FIFOs
    my $jobs = Thread::Queue->new();
    my $done = Thread::Queue->new();

    # count devices and check skip_start_stop
    my $devices_count   = 0;
    my $skip_start_stop = 0;
    foreach my $job (@{$self->{jobs}}) {
        $devices_count += $job->count();
        # newer server won't need START message if PID is provided on <DEVICE/>
        $skip_start_stop = any { defined($_->{PID}) } $job->devices()
            unless $skip_start_stop;
    }

    # Define a job expiration: 15 minutes by device to scan should be enough, but not less than an hour
    my $target_expiration = 900;
    my $global_timeout = $devices_count * $target_expiration;
    $global_timeout = 3600 if $global_timeout < 3600;
    setExpirationTime( timeout => $global_timeout );
    my $expiration = getExpirationTime();
    $self->_logExpirationHours($expiration);

    # no need more threads than devices to scan
    my $threads_count = $max_threads > $devices_count ? $devices_count : $max_threads;

    $self->{logger}->debug("creating $threads_count worker threads");
    for (my $i = 0; $i < $threads_count; $i++) {
        my $newthread = threads->create(sub { $self->_inventory_thread($jobs, $done); });
        # Keep known created threads in a hash
        $running_threads{$newthread->tid()} = $newthread ;
        usleep(50000) until ($newthread->is_running() || $newthread->is_joinable());
    }

    # Check really started threads number vs really running ones
    my @really_running  = map { $_->tid() } threads->list(threads::running);
    my @started_threads = keys(%running_threads);
    unless (@really_running == $threads_count && keys(%running_threads) == $threads_count) {
        $self->{logger}->debug(scalar(@really_running)." really running: [@really_running]");
        $self->{logger}->debug(scalar(@started_threads)." started: [@started_threads]");
    }

    my %queues = ();
    my $pid_index = 1;

    # Start jobs by preparing queues
    foreach my $job (@{$self->{jobs}}) {

        # SNMP credentials
        my $credentials = $job->credentials();

        # set pid
        my $pid = $job->pid() || $pid_index++;

        # send initial message to server unless it supports newer protocol
        $self->_sendStartMessage($pid) unless $skip_start_stop;

        # prepare queue
        my $queue = $queues{$pid} || {
            max_in_queue    => $job->max_threads(),
            in_queue        => 0,
            todo            => []
        };
        foreach my $device ($job->devices()) {
            push @{$queue->{todo}}, {
                pid         => $pid,
                device      => $device,
                timeout     => $job->timeout(),
                credentials => $credentials->{$device->{AUTHSNMP_ID}}
            };
        }

        # Only keep queue if we have a device to scan
        $queues{$pid} = $queue
            if @{$queue->{todo}};
    }

    my $queued_count = 0;
    my $job_count = 0;
    my $jid_len = length(sprintf("%i",$devices_count));
    my $jid_pattern = "#%0".$jid_len."i";

    # We need to guaranty we don't have more than max_in_queue device in shared
    # queue for each job
    while (my @pids = sort { $a <=> $b } keys(%queues)) {

        # Enqueue as device as possible
        foreach my $pid (@pids) {
            my $queue = $queues{$pid};
            next unless @{$queue->{todo}};
            next if $queue->{in_queue} >= $queue->{max_in_queue};
            my $device = shift @{$queue->{todo}};
            $queue->{in_queue} ++;
            $device->{jid} = sprintf($jid_pattern, ++$job_count);
            $jobs->enqueue($device);
            $queued_count++;
        }

        # as long as some of our threads are still running...
        if (keys(%running_threads)) {

            # send available results on the fly
            while (my $device = $done->dequeue_nb()) {
                my $pid = $device->{pid};
                my $queue = $queues{$pid};
                $queue->{in_queue} --;
                $queued_count--;
                unless ($queue->{in_queue} || @{$queue->{todo}}) {
                    # send final message to the server before cleaning threads unless it supports newer protocol
                    $self->_sendStopMessage($pid) unless $skip_start_stop;

                    delete $queues{$pid};

                    # send final message to the server unless it supports newer protocol
                    $self->_sendStopMessage($pid) unless $skip_start_stop;
                }
                # Check if it's time to abort a thread
                $devices_count--;
                if ($devices_count < $threads_count) {
                    $jobs->enqueue({ leave => 1 });
                    $threads_count--;
                } elsif ($threads_count > 1 && $devices_count > 4) {
                    # Only reduce expiration when still using all threads or few devices are still to be scanned
                    $expiration -= $target_expiration;
                    $self->_logExpirationHours($expiration);
                }
            }

            # wait for a little
            usleep(50000);

            if ($expiration && time > $expiration) {
                $self->{logger}->warning("Aborting netinventory job as it reached expiration time");
                # detach all our running worker
                foreach my $tid (keys(%running_threads)) {
                    $running_threads{$tid}->detach()
                        if $running_threads{$tid}->is_running();
                    delete $running_threads{$tid};
                }
                last;
            }

            # List our created and possibly running threads in a list to check
            my %running_threads_checklist = map { $_ => 0 }
                keys(%running_threads);

            foreach my $running (threads->list(threads::running)) {
                my $tid = $running->tid();
                # Skip if this running thread tid is not is our started list
                next unless exists($running_threads{$tid});

                # Check a thread is still running
                $running_threads_checklist{$tid} = 1 ;
            }

            # Clean our started list from thread tid that don't run anymore
            foreach my $tid (keys(%running_threads_checklist)) {
                delete $running_threads{$tid}
                    unless $running_threads_checklist{$tid};
            }
            last unless keys(%running_threads);
        }
    }

    if ($queued_count) {
        $self->{logger}->error("$queued_count devices inventory are missing");
    }

    # Send exit message if we quit during a job still being run
    foreach my $pid (sort { $a <=> $b } keys(%queues)) {
        $self->{logger}->error("job $pid aborted");
        $self->_sendExitMessage($pid);
    }

    # Cleanup joinable threads
    $_->join() foreach threads->list(threads::joinable);
    $self->{logger}->debug("All netinventory threads terminated")
        unless threads->list(threads::running);

    # Reset expiration
    setExpirationTime();
}

sub _logExpirationHours {
    my ($self, $expiration) = @_;

    return if $self->{_remaining_next_log} && time < $self->{_remaining_next_log};

    # Turn expiration integer as a float string to compute remaining as a float
    my $remaining = ("$expiration.0" - time)/3600;

    $self->{_remaining_next_log} = time + 600;

    if ($remaining>2) {
        $remaining = sprintf("%.1f hours", $remaining);
    } elsif($remaining<1) {
        my $minutes = int($remaining*60);
        if ($minutes>=10) {
            $remaining = "$minutes minutes";
        } elsif ($minutes>1) {
            $remaining = "few minutes";
        } else {
            $remaining = "soon";
        }
    } else {
        $remaining = sprintf("%.1f hour", $remaining);
    }

    $self->{logger}->debug("Current run expiration timeout: $remaining");
}

sub _sendMessage {
    my ($self, $content) = @_;

    my $message = GLPI::Agent::XML::Query->new(
        deviceid => $self->{deviceid} || 'foo',
        query    => 'SNMPQUERY',
        content  => $content
    );

    # task-specific client, if needed
    unless ($self->{client}) {
        $self->{client} = GLPI::Agent::HTTP::Client::OCS->new(
            logger  => $self->{logger},
            config  => $self->{config},
        );
    }

    $self->{client}->send(
        url     => $self->{target}->getUrl(),
        message => $message
    );
}

sub _sendStartMessage {
    my ($self, $pid) = @_;

    $self->_sendMessage({
        AGENT => {
            START        => 1,
            AGENTVERSION => $GLPI::Agent::Version::VERSION,
        },
        MODULEVERSION => $VERSION,
        PROCESSNUMBER => $pid
    });
}

sub _sendStopMessage {
    my ($self, $pid) = @_;

    $self->_sendMessage({
        AGENT => {
            END => 1,
        },
        MODULEVERSION => $VERSION,
        PROCESSNUMBER => $pid
    });
}

sub _sendExitMessage {
    my ($self, $pid) = @_;

    $self->_sendMessage({
        AGENT => {
            EXIT => 1,
        },
        MODULEVERSION => $VERSION,
        PROCESSNUMBER => $pid
    });
}

sub _sendResultMessage {
    my ($self, $result, $pid) = @_;

    my $content = {
        DEVICE        => $result,
        MODULEVERSION => $VERSION,
        PROCESSNUMBER => $pid || 0
    };

    # Keep STORAGES as CONTENT node like for Computers
    $content->{STORAGES} = delete $result->{STORAGES}
        if $result->{STORAGES};

    $self->_sendMessage($content);
}

sub _queryDevice {
    my ($self, $params) = @_;

    my $credentials = $params->{credentials};
    my $device      = $params->{device};
    my $logger      = $self->{logger};
    my $id          = threads->tid();
    $logger->{prefix} = "[thread $id] $params->{jid}, ";
    $logger->debug(
        "scanning $device->{ID}: $device->{IP}" .
        ( $device->{PORT} ? ' on port ' . $device->{PORT} : '' ) .
        ( $device->{PROTOCOL} ? ' via ' . $device->{PROTOCOL} : '' )
    );

    my $snmp;
    if ($device->{FILE}) {
        GLPI::Agent::SNMP::Mock->require();
        eval {
            $snmp = GLPI::Agent::SNMP::Mock->new(
                ip   => $device->{IP},
                file => $device->{FILE}
            );
        };
        die "SNMP emulation error: $EVAL_ERROR" if $EVAL_ERROR;
    } else {
        eval {
            GLPI::Agent::SNMP::Live->require();
            # AUTHPASSPHRASE & PRIVPASSPHRASE are deprecated but still used by FusionInventory for GLPI plugin
            $snmp = GLPI::Agent::SNMP::Live->new(
                version      => $credentials->{VERSION},
                hostname     => $device->{IP},
                port         => $device->{PORT},
                domain       => $device->{PROTOCOL},
                timeout      => $params->{timeout} || 15,
                community    => $credentials->{COMMUNITY},
                username     => $credentials->{USERNAME},
                authpassword => $credentials->{AUTHPASSPHRASE} // $credentials->{AUTHPASSWORD},
                authprotocol => $credentials->{AUTHPROTOCOL},
                privpassword => $credentials->{PRIVPASSPHRASE} // $credentials->{PRIVPASSWORD},
                privprotocol => $credentials->{PRIVPROTOCOL},
            );
        };
        die "SNMP communication error: $EVAL_ERROR" if $EVAL_ERROR;
    }

    my $result = getDeviceFullInfo(
        id      => $device->{ID},
        type    => $device->{TYPE},
        snmp    => $snmp,
        model   => $params->{model},
        config  => $self->{config},
        logger  => $self->{logger},
        datadir => $self->{datadir}
    );

    # Inserted back device PID in result if set by server
    $result->{PID} = $device->{PID} if defined($device->{PID});

    return $result;
}

1;

__END__

=head1 NAME

GLPI::Agent::Task::NetInventory - Remote inventory support for GLPI Agent

=head1 DESCRIPTION

This task extracts various information from remote hosts through SNMP
protocol:

=over

=item *

printer cartridges and counters status

=item *

router/switch ports status

=item *

relations between devices and router/switch ports

=back

This task requires a GLPI server with a FusionInventory compatible plugin.
