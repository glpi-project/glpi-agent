package GLPI::Agent::Task::NetInventory;

use strict;
use warnings;

use parent 'GLPI::Agent::Task';

use English qw(-no_match_vars);
use Time::HiRes qw(usleep);
use UNIVERSAL::require;
use Parallel::ForkManager;
use File::Path qw(mkpath);

use GLPI::Agent::Version;
use GLPI::Agent::Tools;
use GLPI::Agent::SNMP::Hardware;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Expiration;
use GLPI::Agent::Tools::SNMP;
use GLPI::Agent::HTTP::Client::OCS;
# We need to preload MibSupport configuration before running threads
use GLPI::Agent::SNMP::MibSupport;

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

sub run {
    my ($self, %params) = @_;

    # Just reset event if run as an event to not trigger another one
    $self->resetEvent();

    my $abort = 0;
    $SIG{TERM} = sub { $abort = 1; };

    GLPI::Agent::IEC61850::Device->require();
    push @{$self->{_library_failure}}, "Failed to load GLPI::Agent::IEC61850::Device, iec61850 protocol inventory not supported"
        if $EVAL_ERROR;
    push @{$self->{_library_failure}}, "Failed to load iec61850 perl library, iec61850 protocol inventory not supported"
        unless $INC{'iec61850.pm'};

    # Store glpi_version for this run
    $self->{glpi_version} = $self->{target}->isType('server') ? $self->{target}->getTaskVersion('inventory') : '';
    $self->{glpi_version} = $self->{config}->{'glpi-version'} if empty($self->{glpi_version});

    # Preload MibSupport
    GLPI::Agent::SNMP::MibSupport::preload(
        config  => $self->{config},
        logger  => $self->{logger}
    );

    # Extract greatest max_threads from jobs
    my ($max_threads) = sort { $b <=> $a } map { int($_->max_threads()) }
        @{$self->{jobs}};

    # On windows, max_threads should not be upper than 60 due to a perl limitation
    if ($OSNAME eq 'MSWin32' && $max_threads > 60) {
        $self->{logger}->info("Limiting threads from $max_threads to 60 on MSWin32");
        $max_threads = 60;
    }

    # count devices and check skip_start_stop
    my $devices_count   = 0;
    my $skip_start_stop = 0;
    foreach my $job (@{$self->{jobs}}) {
        $devices_count += $job->count();
        # Support glpi-netdiscovery --control option
        $self->{_control} = $job->control;
        # newer server won't need START message if PID is provided on <DEVICE/>
        next if $skip_start_stop;
        $skip_start_stop = $job->skip_start_stop || any { defined($_->{PID}) } $job->devices();
    }

    # Define a job expiration based on backend-collect-timeout: by default 15 minutes
    # by device to scan should be enough, keeping a large minimal global task expiration of one hour
    my $target_expiration = 5*$self->{config}->{'backend-collect-timeout'};
    my $global_timeout = $devices_count * $target_expiration;
    $global_timeout = 3600 if $global_timeout < 3600;
    setExpirationTime( timeout => $global_timeout );
    my $expiration = getExpirationTime();
    $self->_logExpirationHours($expiration);

    # no need more workers than devices to scan
    my $worker_count = $max_threads > $devices_count ? $devices_count : $max_threads;

    # Prepare fork manager
    $self->{logger}->debug("using $worker_count netinventory worker".($worker_count > 1 ? "s" : ""));
    my $manager = Parallel::ForkManager->new($worker_count > 1 ? $worker_count : 0);
    $manager->set_waitpid_blocking_sleep(0);

    my %jobs = ();
    my $pid_index = 1;

    # Start jobs by preparing queues
    foreach my $job (@{$self->{jobs}}) {

        # set pid
        my $pid = $job->pid() || $pid_index++;

        # send initial message to server in a worker unless it supports newer protocol
        unless ($skip_start_stop || $manager->start(0)) {
            $self->_sendStartMessage($pid);
            $manager->finish();
        }

        # Only keep job if it has devices to scan
        my @devices = $job->devices()
            or next;

        # prepare job
        $jobs{$pid} = $job unless $jobs{$pid};
        $jobs{$pid}->updateQueue(\@devices);
    }
    $manager->wait_all_children();

    my $queued_count = 0;

    # Callback for processed device
    $manager->run_on_finish(
        sub {
            my ($pid, $ret, $jobid) = @_;
            return unless $jobid;
            my $job = $jobs{$jobid};
            $queued_count--;
            delete $jobs{$jobid} if $job->done;
            $devices_count--;
            # Only reduce expiration when few devices are still to be scanned
            if ($devices_count > 4 && $expiration > time + $devices_count*$target_expiration) {
                $expiration -= $target_expiration;
                setExpirationTime( expiration => $expiration );
                $self->_logExpirationHours($expiration);
            }
        }
    );

    my $job_count = 0;
    my $jid_len = length(sprintf("%i",$devices_count));
    my $jid_pattern = "#%0".$jid_len."i, ";

    # We need to guaranty we don't have more than max_in_queue request in queue for each job
    while (my @pids = sort { $a <=> $b } keys(%jobs)) {

        # Enqueue as device as possible for each job
        foreach my $pid (@pids) {
            # job may has just been done & deleted in run_on_finish() manager callback
            my $job = $jobs{$pid}
                or next;
            next if $job->no_more || $job->max_in_queue;
            my $device = $job->nextdevice
                or next;

            $queued_count++;

            if ($expiration && time > $expiration) {
                $self->{logger}->warning("Aborting netinventory job as it reached expiration time");
                $self->{logger}->info("You can set backend-collect-timout higher than the default to use a longer expiration timeout");
                $abort ++;
                last;
            }

            if ($abort) {
                $self->{logger}->warning("Aborting netinventory task on TERM signal");
                last;
            }

            $job_count++;

            # Start worker and still try to enqueue another device for this job
            $manager->start($pid) and redo;

            # logprefix can still be set by NetDiscovery task if netscan is enabled
            $self->{logger}->{prefix} = sprintf($jid_pattern, $job_count)
                unless $self->{logger}->{prefix};

            my $result = $self->_queryDevice(
                pid     => $pid,
                job     => $job,
                device  => $device
            );
            unless (ref($result)) {
                my $error = empty($result) ?
                    "Failed netinventory processing on ".$device->{IP} : $result;

                $result = {
                    ERROR => {
                        ID      => $device->{ID},
                        MESSAGE => $error
                    }
                };

                $result->{ERROR}->{TYPE} = $device->{TYPE} if $device->{TYPE};

                # Inserted back device PID in result if set by server
                $result->{PID} = $device->{PID} if defined($device->{PID});

                $self->{logger}->error($error);
            }

            # Get result PID from result
            my $thispid = delete $result->{PID} // $pid;

            # Directly send the result message from the worker, but use job pid if
            # it was not set in result
            $self->_sendResultMessage($result, $thispid, $device->{IP});

            # Send control messages unless not required
            if (!$skip_start_stop || $self->{_control}) {
                # send end message to the server for this job
                $self->_sendStopMessage($thispid);

                # send final end message to the server
                $self->_sendStopMessage($thispid);
            }

            delete $self->{logger}->{prefix} if $worker_count > 1;

            $manager->finish(0);
        }

        last if $abort;

        # wait a little bit
        usleep(50000);
        $manager->reap_finished_children();
    }

    $manager->wait_all_children();

    $self->{logger}->debug($worker_count>1 ? "All netinventory workers terminated" : "Netinventory worker terminated");

    if ($queued_count) {
        $self->{logger}->error("$queued_count devices inventory are missing");
    }

    # Send exit message if we quit during a job still being run
    foreach my $pid (sort { $a <=> $b } keys(%jobs)) {
        $self->{logger}->warning("job $pid aborted");
        $self->_sendExitMessage($pid);
    }

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

    $self->{logger}->debug("Current netinventory run expiration timeout: $remaining");
}

sub _sendMessage {
    my ($self, $content, $ip, $itemtype) = @_;

    # Load GLPI::Agent::XML::Query as late as possible
    return unless GLPI::Agent::XML::Query->require();

    my $message = GLPI::Agent::XML::Query->new(
        deviceid => $self->{deviceid} || 'foo',
        query    => 'SNMPQUERY',
        itemtype => $itemtype,
        content  => $content
    );

    if ($self->{target}->isType('local')) {
        my ($handle, $file);
        my $path = $self->{target}->getPath();
        if ($path eq '-') {
            return unless $content->{DEVICE} || $self->{_control};
            $handle = \*STDOUT;
        } else {
            return unless $content->{DEVICE};
            $path = $self->{target}->getFullPath("netinventory");
            mkpath($path) unless -d $path;
            $file = $path . "/$ip.xml";
        }

        if ($file) {
            if ($OSNAME eq 'MSWin32' && Win32::Unicode::File->require()) {
                $handle = Win32::Unicode::File->new('w', $file)
                    or $self->{logger}->error("Can't write to $file: $ERRNO");
            } else {
                open($handle, '>', $file)
                    or $self->{logger}->error("Can't write to $file: $ERRNO");
            }
            return unless $handle;
            $self->{logger}->info("Netinventory result for $ip saved in $file");
        }

        print $handle $message->getContent();
        close($handle) if $file;

    } elsif ($self->{target}->isType('server')) {
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
    my ($self, $result, $pid, $ip) = @_;

    # Prepare to move ITEMTYPE if defined to the expected place
    my $itemtype = delete $result->{ITEMTYPE};

    my $content = {
        DEVICE        => $result,
        MODULEVERSION => $VERSION,
        PROCESSNUMBER => $pid || 0
    };

    # Keep STORAGES as CONTENT node like for Computers
    $content->{STORAGES} = delete $result->{STORAGES}
        if $result->{STORAGES};

    $self->_sendMessage($content, $ip, $itemtype);
}

sub _queryDevice {
    my ($self, %params) = @_;

    my $job = $params{job};
    my $device = $params{device};

    my $credential;
    my $have_credential = 0;

    my $result;

    if ($INC{'iec61850.pm'}) {
        $credential = $device->{AUTHIEC_ID} ?
            $job->credential($device->{AUTHIEC_ID}) : { ID  => "no", PORT => 102 };
    } elsif ($self->{_library_failure}) {
        # This is time to share one time if we failed to load iec61850 protocol support libraries
        my $errors = delete $self->{_library_failure};
        map { $self->{logger}->info($_) } @{$errors};
    }

    if ($credential && !$device->{FILE}) {
        $have_credential++;

        # Normalize port with 102 as default port
        my $port = $credential->{PORT} && isInteger($credential->{PORT}) ?
            int($credential->{PORT}) : 102;
        $port = 102 unless $port > 0 && $port <= 65535;

        eval {
            my $iecdevice = GLPI::Agent::IEC61850::Device->new(
                timeout => $job->timeout() || 1,
                glpi    => $self->{glpi_version} || '',
                logger  => $self->{logger},
            );
            $result = $iecdevice->scan($device->{IP}, $port);
            $result = $iecdevice->inventory($result)
                if $result;
        };

        $self->{logger}->debug(
            sprintf "iec61850 scan of %s%s with %s: %s",
            $device->{IP},
            $port != 102 ? ':'.$port : '',
            isInteger($credential->{ID}) ? "credential #".$credential->{ID} : $credential->{ID}." credential",
            $result ? 'success' : $EVAL_ERROR ? 'not supported' : 'no result'
        );

    }

    $credential = $job->credential($device->{AUTHSNMP_ID})
        if $device->{AUTHSNMP_ID};

    if ($device->{AUTHSNMP_ID} && $credential) {
        my ($snmp, $error);
        $have_credential++;

        $self->{logger}->debug(
            "full snmp scan of $device->{IP}" .
            ( $credential->{PORT} ? ' on port ' . $credential->{PORT} : '' ) .
            ( $credential->{PROTOCOL} ? ' via ' . $credential->{PROTOCOL} : '' ) .
            " with credentials " . $device->{AUTHSNMP_ID}
        );

        if ($device->{FILE}) {
            GLPI::Agent::SNMP::Mock->require();
            eval {
                $snmp = GLPI::Agent::SNMP::Mock->new(
                    ip   => $device->{IP},
                    file => $device->{FILE}
                );
            };
            $error = "SNMP emulation error: $EVAL_ERROR"
                if $EVAL_ERROR;
        } else {
            eval {
                GLPI::Agent::SNMP::Live->require();
                # AUTHPASSPHRASE & PRIVPASSPHRASE are deprecated but still used by FusionInventory for GLPI plugin
                $snmp = GLPI::Agent::SNMP::Live->new(
                    version      => $credential->{VERSION},
                    hostname     => $device->{IP},
                    timeout      => $job->timeout() || 15,
                    community    => $credential->{COMMUNITY},
                    username     => $credential->{USERNAME},
                    authpassword => $credential->{AUTHPASSPHRASE} // $credential->{AUTHPASSWORD},
                    authprotocol => $credential->{AUTHPROTOCOL},
                    privpassword => $credential->{PRIVPASSPHRASE} // $credential->{PRIVPASSWORD},
                    privprotocol => $credential->{PRIVPROTOCOL},
                    contextname  => $credential->{CONTEXTNAME},
                    port         => $credential->{PORT} // 161,
                    domain       => $credential->{PROTOCOL} // "udp",
                    retries      => $self->{config}->{'snmp-retries'} // 0,
                );
                $snmp->testSession();
            };
            $error = "SNMP communication error: $EVAL_ERROR"
                if $EVAL_ERROR;
        }

        if ($error) {
            chomp($error);
            $self->{logger}->debug("full snmp scan of $device->{IP} failure: $error");
            return $error;
        } else {
            my $snmpresult = getDeviceFullInfo(
                id      => $device->{ID},
                type    => $device->{TYPE},
                snmp    => $snmp,
                config  => $self->{config},
                logger  => $self->{logger},
                # Include glpi version if known so modules can verify it for supported feature
                glpi    => $self->{glpi_version} || '',
                datadir => $self->{datadir}
            );

            # Merge snmp result
            foreach my $key (keys(%{$snmpresult})) {
                $result->{$key} = $snmpresult->{$key};
            }
        }
    }

    # Check no credential error
    my $credential_error = "";
    $credential_error = "no iec61850 credential provided"
        if !$have_credential && $device->{AUTHIEC_ID};

    $credential_error .= ($credential_error ? ", " : "")."no SNMP credential provided"
        if !$have_credential && $device->{AUTHSNMP_ID};

    return $credential_error unless $have_credential;

    # Inserted back device PID in result if set by server
    $result->{PID} = $device->{PID} if $result && defined($device->{PID});

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
