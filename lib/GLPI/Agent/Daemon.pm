package GLPI::Agent::Daemon;

use strict;
use warnings;

use Cwd;
use English qw(-no_match_vars);
use UNIVERSAL::require;
use POSIX ":sys_wait_h"; # WNOHANG
use Time::HiRes qw(usleep);

# By convention, we just use 5 chars string as possible internal IPC messages.
# IPC_LEAVE from children is supported and is only really useful while debugging.
# IPC_EVENT can be used to handle events recognized in parent
# IPC_EFILE can be used to handle events recognized in parent and is used on MSWin32
#           when transmitted event is too big for IPC
# IPC_ABORT can be used to abort a forked process
use constant IPC_LEAVE  => 'LEAVE';
use constant IPC_EVENT  => 'EVENT';
use constant IPC_ABORT  => 'ABORT';
use constant IPC_EFILE  => 'EFILE';

use parent 'GLPI::Agent';

use GLPI::Agent::Logger;
use GLPI::Agent::Version;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;
use GLPI::Agent::Protocol::Contact;
use GLPI::Agent::Event;

my $PROVIDER = $GLPI::Agent::Version::PROVIDER;

# Avoid being killed on early SIGUSR1 signal
my $runnow = 0;
$SIG{USR1} = sub { $runnow = 1; }
    unless $OSNAME eq 'MSWin32';

sub init {
    my ($self, %params) = @_;

    $self->{lastConfigLoad} = time;

    $self->SUPER::init(%params);

    $self->createDaemon();

    # Register ourself as an event handler
    $self->register_events_cb($self);

    # create HTTP interface if required
    $self->loadHttpInterface();

    $self->ApplyServiceOptimizations();

    # Trigger init event on each tasks for each target
    map { $_->triggerTaskInitEvents() } $self->getTargets();

    # install signal handler to handle reload signal
    $SIG{HUP} = sub { $self->reinit(); };
    $SIG{USR1} = sub { $self->runNow(); }
        unless ($OSNAME eq 'MSWin32');

    # Handle USR1 signal received during start
    if ($runnow) {
        $runnow = 0;
        $self->runNow();
    }
}

sub reinit {
    my ($self) = @_;

    # Update PID file modification time so we can expire it
    utime undef,undef,$self->{pidfile} if $self->{pidfile};

    $self->{logger}->debug('agent reinit');

    $self->{lastConfigLoad} = time;

    $self->{config}->reload();

    # Reload init from parent class
    $self->SUPER::init();

    # Reload HTTP interface if required
    $self->loadHttpInterface();

    $self->ApplyServiceOptimizations();

    $self->{logger}->debug('agent reinit done.');
}

sub run {
    my ($self) = @_;

    my $config = $self->{config};
    my $logger = $self->{logger};

    $self->setStatus('waiting');

    my @targets = $self->getTargets();

    if ($logger) {
        if ($config->{'no-fork'}) {
            $logger->debug2("Waiting in mainloop");
        } else {
            $logger->debug("Running in background mode");
        }
        foreach my $target (@targets) {
            my $date = $target->getFormatedNextRunDate();
            my $id   = $target->id();
            my $info = $target->isType('local') ? $target->getFullPath() : $target->getName();
            $logger->info("target $id: next run: $date - $info");
        }
    }

    # background mode: work on a targets list copy, but loop while
    # the list really exists so we can stop quickly when asked for
    while ($self->getTargets()) {
        my $time = time();

        @targets = $self->getTargets() unless @targets;
        my $target = shift @targets;

        $self->_reloadConfIfNeeded();

        # Still get next event, as we don't want to handle job events here but in events_cb called from sleep
        my $event = $target->nextEvent();

        if ($target->paused()) {

            # Reset target responses
            $target->responses({});

            # Leave immediately if we passed in terminate method
            last if $self->{_terminate};

        } elsif ($event && !$event->job) {
            # Always remove event from list
            $target->delEvent($event);

            my $responses = $target->responses();

            # Contact server if required and cache responses
            if ($event->taskrun) {
                if ((!ref($responses) || !$responses->{CONTACT}) && $target->isGlpiServer()) {
                    $responses->{CONTACT} = $self->getContact($target, [$target->plannedTasks()]);
                }
                if ((!ref($responses) || !$responses->{PROLOG}) && $target->isType('server') && $event->task =~ /^net(discovery|inventory)$/i) {
                    $responses->{PROLOG} = $self->getProlog($target);
                }
                if ($target->isType('server')) {
                    # Fail event on no expected response from server
                    unless (ref($responses) && (ref($responses->{CONTACT}) || ref($responses->{PROLOG}))) {
                        $logger->error("Failed to handle run event for ".$event->task) if $logger && $event->task;
                        next;
                    }

                    # Keep target responses
                    $target->responses($responses);
                }
            }

            eval {
                $self->runTargetEvent($target, $event, $responses);
            };
            $logger->error($EVAL_ERROR) if ($EVAL_ERROR && $logger);

            # Leave immediately if we passed in terminate method
            last if $self->{_terminate};

            # Reschedule if required
            if ($event->taskrun && $event->get('reschedule')) {
                # First set rundate to now, than reset next run date
                $target->setNextRunDateFromNow();
                $target->resetNextRunDate();

                # This is also safe to reset target responses
                $target->responses({});

                if ($logger) {
                    my $date = $target->getFormatedNextRunDate();
                    my $id   = $target->id();
                    my $name = $target->getName();
                    $logger->info("target $id: next run: $date - $name");
                }
            }

            # We should run service optimization after all targets can be run
            $self->{_run_optimization} = scalar($self->getTargets());

        } elsif ($time >= $target->getNextRunDate()) {

            my $net_error = 0;
            eval {
                $net_error = $self->runTarget($target);
            };
            $logger->error($EVAL_ERROR) if ($EVAL_ERROR && $logger);
            if ($net_error) {
                # Prefer to retry early on net error
                $target->setNextRunDateFromNow(60);
            } else {
                $target->resetNextRunDate();
            }

            if ($logger) {
                my $date = $target->getFormatedNextRunDate();
                my $id   = $target->id();
                my $name = $target->getName();
                $logger->info("target $id: next run: $date - $name");
            }

            # Leave immediately if we passed in terminate method
            last if $self->{_terminate};

            # We should run service optimization after all targets can be run
            $self->{_run_optimization} = scalar($self->getTargets());
        }

        # Call service optimization after all target has been run
        if (defined($self->{_run_optimization}) && $self->{_run_optimization}-- <= 1) {
            $self->RunningServiceOptimization();
            delete $self->{_run_optimization};
        }

        # This eventually check for http messages, default timeout is 1 second
        $self->sleep();
    }
}

sub runNow {
    my ($self) = @_;

    foreach my $target ($self->getTargets()) {
        $target->setNextRunDateFromNow();
    }

    $self->{logger}->info("$PROVIDER Agent requested to run all targets now");
}

sub _reloadConfIfNeeded {
    my ($self) = @_;

    my $reloadInterval = $self->{config}->{'conf-reload-interval'} || 0;

    return unless ($reloadInterval > 0);

    my $reload = time - $self->{lastConfigLoad} - $reloadInterval;

    $self->reinit() if ($reload > 0);
}

sub runTargetEvent {
    my ($self, $target, $event, $responses) = @_;

    # Just ignore event if invalid
    return unless $event && $event->name && $event->task;

    my $task = $event->task;
    my %modulesmap = qw(
        netdiscovery    NetDiscovery
        netinventory    NetInventory
        remoteinventory RemoteInventory
        esx             ESX
        wakeonlan       WakeOnLan
    );
    my $realtask = $modulesmap{$task} || ucfirst($task);

    $self->{logger}->debug("target ".$target->id().": ".$event->name()." event for $realtask task")
        unless $event->runnow;

    $self->{event} = $event;

    if ($event->init) {
        eval {
            # We don't need to fork for init event
            $self->runTaskReal($target, $realtask);
        };

    } elsif ($event->runnow) {
        $target->triggerRunTasksNow($event);

    } elsif (ref($responses)) {
        my $server_response = $responses->{PROLOG};
        if ($responses->{CONTACT}) {
            # Be sure to use expected response for task
            my $task_server = $target->getTaskServer($task) // 'glpi';
            $server_response = $responses->{CONTACT}
                if $task_server eq 'glpi';
        }
        eval {
            $self->runTask($target, $realtask, $server_response);
        };
        $self->{logger}->error($EVAL_ERROR) if $EVAL_ERROR;
        $self->setStatus($target->paused() ? 'paused' : 'waiting');

    } else {
        # Simulate CONTACT server response
        my $contact = GLPI::Agent::Protocol::Contact->new(
            tasks => { $task => { params => [ $event->params ] }}
        );
        eval {
            $self->runTask($target, $realtask, $contact);
        };
        $self->{logger}->error($EVAL_ERROR) if $EVAL_ERROR;
        $self->setStatus($target->paused() ? 'paused' : 'waiting');
    }

    delete $self->{event};
}

sub runTask {
    my ($self, $target, $name, $response) = @_;

    $self->setStatus("running task $name");

    # server mode: run each task in a child process
    if (my $pid = $self->fork()) {

        # parent
        $self->{current_runtask} = $pid;

        while (waitpid($pid, WNOHANG) == 0) {
            # Wait but eventually handle http server requests
            $self->sleep();

            # Leave earlier while requested
            last if $self->{_terminate};
        }
        delete $self->{current_runtask};

    } else {
        # child
        die "fork failed: $ERRNO\n" unless defined $pid;

        # Don't handle HTTPD interface in forked child
        delete $self->{server};
        delete $self->{pidfile};
        delete $self->{_fork};

        # Mostly to update process name on unix platforms
        $self->setStatus("task $name");

        $self->{logger}->debug("forking process $$ to handle task $name");

        $self->runTaskReal($target, $name, $response);

        $self->fork_exit(0);
    }
}

sub handleTaskCache {
    my ($self, $name, $task) = @_;

    return unless $task && $task->keepcache();

    # Try to cache data provided by the task if the next run can require it
    my $cachedata = $task->cachedata();
    if (defined($cachedata) && GLPI::Agent::Protocol::Message->require()) {
        my $data = GLPI::Agent::Protocol::Message->new(message => $cachedata);
        $self->forked_process_event("AGENTCACHE,$name,".$data->getRawContent());
    }
}

sub handleTaskEvent {
    my ($self, $name, $task) = @_;

    return unless $task && GLPI::Agent::Protocol::Message->require();

    foreach my $event ($task->events()) {
        my $message = GLPI::Agent::Protocol::Message->new(message => $event->dump_for_message());
        $self->forked_process_event("TASKEVENT,".($event->task||$name).",".$message->getRawContent());
    }
}

sub createDaemon {
    my ($self) = @_;

    my $config = $self->{config};
    my $logger = $self->{logger};

    # Don't try to create a daemon if configured as a service
    if ($config->{service}) {
        # From here we can also support process forking
        $self->{_fork} = {} unless $self->{_fork};
        return $logger->info("$PROVIDER Agent service starting");
    }

    $logger->info("$PROVIDER Agent starting");

    my $pidfile = $config->{pidfile};

    if (defined($pidfile) && $pidfile eq "") {
        # Set to default pidfile only when needed
        $pidfile = $self->{vardir} . '/'. lc($PROVIDER). '-agent.pid';
        $logger->debug("Using $pidfile as default PID file") if $logger;
    } elsif (!$pidfile) {
        $logger->debug("Skipping running daemon control based on PID file checking") if $logger;
    }

    # Expire PID file if daemon is not running while conf-reload-interval is
    # in use and PID file has not been update since, including a minute safety gap
    if ($pidfile && -e $pidfile && $self->{config}->{'conf-reload-interval'}) {
        my $mtime = (stat($pidfile))[9];
        if ($mtime && $mtime < time - $self->{config}->{'conf-reload-interval'} - 60) {
            $logger->info("$pidfile PID file expired") if $logger;
            unlink $pidfile;
        }
    }

    my $daemon;

    Proc::Daemon->require() unless $config->{'no-fork'};
    if ($config->{'no-fork'} || $EVAL_ERROR) {
        $logger->debug("Failed to load recommended Proc::Daemon library: $EVAL_ERROR")
            if !$config->{'no-fork'} && $logger;

        # Eventually check running process from pid found in pid file
        if ($pidfile) {
            my $pid = getFirstLine(file => $pidfile);

            if ($pid && int($pid)) {
                $logger->debug2("Last running daemon started with PID $pid") if $logger;
                if ($pid != $$ && kill(0, $pid)) {
                    $logger->error("$PROVIDER Agent is already running, exiting...") if $logger;
                    exit 1;
                }
                $logger->debug("$PROVIDER Agent with PID $pid is dead") if $logger;
            }
        }

    } else {
        # If we use relative path, we must stay in the current directory
        my $workdir = substr($self->{libdir}, 0, 1) eq '/' ? '/' : getcwd();

        # Be sure to keep libdir in includes or we can fail to load need libraries
        unshift @INC, $self->{libdir}
            if ($workdir eq '/' && ! first { $_ eq $self->{libdir} } @INC);

        $daemon = Proc::Daemon->new(
            work_dir => $workdir,
            pid_file => $pidfile
        );

        # Use Proc::Daemon API to check daemon status but it always return false
        # if pidfile is not used
        if ($daemon->Status()) {
            $logger->error("$PROVIDER Agent is already running, exiting...") if $logger;
            exit 1;
        }
    }

    if ($config->{'no-fork'} || !$daemon) {
        # Still keep current PID in PID file to permit Proc::Daemon to check status
        if ($pidfile) {
            if (open(my $pid, ">", $pidfile)) {
                print $pid "$$\n";
                close($pid);
            } elsif ($logger) {
                $logger->debug("Can't write PID file: $!");
                undef $pidfile;
            }
        }
        $logger->debug("$PROVIDER Agent started in foreground") if $logger;

    } elsif (my $pid = $daemon->Init()) {
        $logger->debug("$PROVIDER Agent daemonized with PID $pid") if $logger;
        exit 0;
    } else {
        # Reload the logger in forked process to avoid some related issues
        $logger->reload();
    }

    # From here we can enable our pidfile deletion on terminate
    $self->{pidfile} = $pidfile;

    # From here we can also support process forking
    $self->{_fork} = {} unless $self->{_fork};
}

sub register_events_cb {
    my ($self, $object) = @_;
    return unless defined($object);
    push @{$self->{_events_cb}}, $object;
}

sub _trigger_event {
    my ($self, $event) = @_;
    return unless defined($event) && defined($self->{_events_cb});
    foreach my $object (@{$self->{_events_cb}}) {
        last if $object->events_cb($event);
    }
}

sub events_cb {
    my ($self, $event) = @_;

    return unless defined($event);

    my ($type, $task, $dump) = $event =~ /^(AGENTCACHE|TASKEVENT),([^,]*),(.*)$/ms
        or return 0;

    if ($type eq 'AGENTCACHE' && $dump =~ /^\{/ && GLPI::Agent::Protocol::Message->require()) {
        my $data = GLPI::Agent::Protocol::Message->new(message => $dump);
        $self->{_cache}->{$task} = $data->get;
    } elsif ($type eq 'TASKEVENT' && $dump =~ /^\{/ && GLPI::Agent::Protocol::Message->require()) {
        my $message = GLPI::Agent::Protocol::Message->new(message => $dump);
        my $event = GLPI::Agent::Event->new(from_message => $message->get);
        my $targetid = $event->target;
        my @targets = grep { !$targetid || $_->id() eq $targetid } $self->getTargets();
        map { $_->addEvent($event) } @targets;
    }
}

sub handleChildren {
    my ($self) = @_;

    return unless $self->{_fork};

    my $count = 0;
    my @processes = keys(%{$self->{_fork}});
    foreach my $pid (@processes) {
        my $child = $self->{_fork}->{$pid};

        # Check if any forked process is communicating
        my @messages;
        delete $child->{in} unless $child->{in} && $child->{in}->opened;
        while ($child->{in} && $child->{pollin} && $child->{poll} && &{$child->{poll}}($child->{pollin})) {
            my $msg = " " x 5;
            if ($child->{in}->sysread($msg, 5)) {
                if ($msg eq IPC_LEAVE) {
                    $self->child_exit($pid);
                } elsif ($msg eq IPC_EVENT) {
                    my $len;
                    $len = unpack("S", $len)
                        if $child->{in}->sysread($len, 2);
                    if ($len) {
                        my $event;
                        push @messages, $event
                            if $child->{in}->sysread($event, $len);
                    }
                } elsif ($msg eq IPC_EFILE) {
                    my $len;
                    $len = unpack("S", $len)
                        if $child->{in}->sysread($len, 2);
                    if ($len>2) {
                        my ($event, $size, $file);
                        $size = unpack("S", $size)
                            if $child->{in}->sysread($size, 2);
                        if ($child->{in}->sysread($file, $len-2)) {
                            $event = GLPI::Agent::Tools::Win32::readEventFile($file, $size);
                            if (!defined($event) || length($event) != $size) {
                                # Limit log rate of IPC_EVENT event read failure from IPC_EFILE
                                if (!$self->{_efile_logger_failure_timeout} || time > $self->{_efile_logger_failure_timeout}) {
                                    $self->{logger}->debug2($child->{name} . "[$pid] failed to read IPC_EVENT from $file file");
                                    $self->{_efile_logger_failure_timeout} = time + 5;
                                }
                            } else {
                                push @messages, $event;
                            }
                        }
                    }
                }
            }
            $count++;
        }

        # Trigger events after they have been read
        map { $self->_trigger_event($_) } @messages;

        # Check if any forked process has been finished
        waitpid($pid, WNOHANG)
            or next;
        $self->child_exit($pid);
        delete $self->{_fork}->{$pid};
        $self->{logger}->debug2($child->{name} . "[$pid] finished");
    }

    return $count;
}

sub sleep {
    my ($self) = @_;

    # Check if any forked process has been finished or is speaking
    if ($self->handleChildren()) {
        $self->{_shorter_delay} = time + 60;
    }

    # Trigger an empty event to permit sanity checks
    # Used by proxy mode to free stored requestid when client doesn't come back
    map { $_->events_cb() } @{$self->{_events_cb}}
        if defined($self->{_events_cb});

    eval {
        local $SIG{PIPE} = 'IGNORE';
        # Check for http interface messages, default timeout is 1 second
        if ($self->{server} && $self->{server}->handleRequests()) {
            $self->{_shorter_delay} = time + 60;
        } else {
            if ($self->{_shorter_delay}) {
                if (time < $self->{_shorter_delay}) {
                    usleep 100000;
                } else {
                    usleep 1000000;
                    delete $self->{_shorter_delay};
                }
            } else {
                usleep 1000000;
            }
        }
    };
    $self->{logger}->error($EVAL_ERROR) if ($EVAL_ERROR && $self->{logger});
}

sub fork {
    my ($self, %params) = @_;

    # Only fork if we are authorized
    return unless $self->{_fork};

    my ($child_ipc, $parent_ipc, $ipc_poller);
    my $logger = $self->{logger};
    my $name = $params{name} || "child";
    my $info = $params{description} || "$name job";

    # Try to setup an optimized internal IPC based on IO::Pipe & IO::Poll objects
    IO::Pipe->require();
    if ($EVAL_ERROR) {
        $logger->debug("Can't use IO::Pipe for internal IPC support: $!");
    } else {
        unless ($child_ipc = IO::Pipe->new()) {
            $logger->debug("forking $name process without IO::Pipe support: $!");
        }

        if ($child_ipc && not $parent_ipc = IO::Pipe->new()) {
            $logger->debug("forking $name process without IO::Pipe support: $!");
        }

        if ($OSNAME ne 'MSWin32') {
            IO::Poll->require();
            if ($EVAL_ERROR) {
                $logger->debug("Can't use IO::Poll to support internal IPC: $!");
            } else {
                $ipc_poller = IO::Poll->new();
            }
        } else {
            GLPI::Agent::Tools::Win32->require();
            $ipc_poller = GLPI::Agent::Tools::Win32::newPoller();
        }
    }

    my $pid = fork();

    unless (defined($pid)) {
        $logger->error("Can't fork a $name process: $!");
        return;
    }

    if ($pid) {
        # In parent
        $self->{_fork}->{$pid} = {
            name    => $name,
            id      => $params{id} || $pid,
        };
        if ($child_ipc && $parent_ipc) {
            # Try to setup an optimized internal IPC based on IO::Pipe objects
            $child_ipc->reader();
            $parent_ipc->writer();
            if ($ipc_poller) {
                $ipc_poller->mask($child_ipc => IO::Poll::POLLIN)
                    unless $OSNAME eq 'MSWin32';
                $self->{_fork}->{$pid}->{pollin} = $ipc_poller;
                $self->{_fork}->{$pid}->{poll} = $OSNAME ne 'MSWin32' ?
                    sub {
                        my ($poller) = @_;
                        return $poller->poll(0) ;
                    } :
                    sub {
                        my ($poller) = @_;
                        return GLPI::Agent::Tools::Win32::getPoller($poller);
                    };
            }
            $self->{_fork}->{$pid}->{in}  = $child_ipc;
            $self->{_fork}->{$pid}->{out} = $parent_ipc;
        }
        $logger->debug("forking process $pid to handle $info");
    } else {
        # In child
        $self->setStatus("processing $info");
        delete $self->{server};
        delete $self->{pidfile};
        delete $self->{current_runtask};
        delete $self->{_fork};
        if ($child_ipc && $parent_ipc) {
            # Try to setup an optimized internal IPC based on IO::Pipe objects
            $child_ipc->writer();
            $parent_ipc->reader();
            if ($ipc_poller) {
                $ipc_poller->mask($parent_ipc => IO::Poll::POLLIN)
                    unless $OSNAME eq 'MSWin32';
                $self->{_ipc_pollin} = $ipc_poller;
            }
            $self->{_ipc_in}  = $parent_ipc;
            $self->{_ipc_out} = $child_ipc;
        }
        $self->{_forked} = 1;
        $logger->debug2("$name\[$$]: forked");
    }

    return $pid;
}

sub forked {
    my ($self, %params) = @_;

    return 1 if $self->{_forked};

    return 0 unless $self->{_fork} && $params{name};

    # Be sure finished children are forgotten before counting forked named children
    $self->handleChildren();

    my @forked = grep { $self->{_fork}->{$_}->{name} eq $params{name} && kill 0, $_ }
        keys(%{$self->{_fork}});

    return scalar(@forked);
}

sub forked_process_event {
    my ($self, $event) = @_;

    return unless $self->forked() && defined($event);

    return unless length($event);
    # On MSWin32, syswrite can block if header+size+event is greater than 512 bytes
    if (length($event) > 505 && $OSNAME eq 'MSWin32') {
        my ($type) = split(",", $event)
            or return;
        $type = substr($event, 0, 64) if length($type) > 64;
        # Just ignore too big logger event like full inventory content logged at debug2 level
        return if $type eq 'LOGGER';

        # Convert event to efile: event content in a file
        my $file = GLPI::Agent::Tools::Win32::getEventFile($self->{vardir}, $event);
        my $efile = pack("S", length($event)).$file;
        $self->{_ipc_out}->syswrite(IPC_EFILE.pack("S", length($efile)).$efile);
        GLPI::Agent::Tools::Win32::setPoller($self->{_ipc_pollin});
        return;
    }

    # Send IPC_EVENT in one message to prevent concurrent syswrite() calls from
    # Parallel::ForkManager children to mix up messages
    $self->{_ipc_out}->syswrite(IPC_EVENT.pack("S", length($event)).$event);
    GLPI::Agent::Tools::Win32::setPoller($self->{_ipc_pollin})
        if $OSNAME eq 'MSWin32';
}

sub abort_child {
    my ($self, $id) = @_;

    return unless $self->{_fork} && defined($id);

    foreach my $pid (keys(%{$self->{_fork}})) {
        my $forked = $self->{_fork}->{$pid};
        next unless $forked->{id} && $forked->{id} eq $id;
        $self->{logger}->debug("aborting $pid child");
        $forked->{out}->syswrite(IPC_ABORT);
        GLPI::Agent::Tools::Win32::setPoller($forked->{pollin})
            if $OSNAME eq 'MSWin32';
        kill 'TERM', $pid;
        return;
    }

    $self->{logger}->debug("Can't abort $id: no such child");
}

sub fork_exit {
    my ($self) = @_;

    return unless $self->forked();

    if ($self->{_ipc_out}) {
        $self->{_ipc_out}->syswrite(IPC_LEAVE);
        $self->{_ipc_out}->close();
        delete $self->{_ipc_out};
    }
    if ($self->{_ipc_in}) {
        $self->{_ipc_in}->close();
        delete $self->{_ipc_in};
        delete $self->{_ipc_pollin};
    }

    exit(0);
}

sub child_exit {
    my ($self, $pid) = @_;

    if ($self->{_fork} && $self->{_fork}->{$pid}) {
        my $child = $self->{_fork}->{$pid};
        if ($child->{out}) {
            $child->{out}->close();
            delete $child->{out};
        }
        if ($child->{in}) {
            $child->{in}->close();
            delete $child->{in};
            delete $child->{pollin};
        }
    }
}

sub loadHttpInterface {
    my ($self) = @_;

    my $config = $self->{config};

    if ($config->{'no-httpd'}) {
        # Handle re-init case
        if ($self->{server}) {
            $self->{server}->stop() ;
            delete $self->{server};
        }
        return;
    }

    my $logger = $self->{logger};

    my %server_config = (
        logger  => $logger,
        agent   => $self,
        htmldir => $self->{datadir} . '/html',
        ip      => $config->{'httpd-ip'},
        port    => $config->{'httpd-port'},
        trust   => $config->{'httpd-trust'}
    );

    # Handle re-init, don't restart httpd interface unless config changed
    if ($self->{server}) {
        return unless $self->{server}->needToRestart(%server_config);
        $self->{server}->stop();
        delete $self->{server};
    }

    GLPI::Agent::HTTP::Server->require();
    if ($EVAL_ERROR) {
        $logger->error("Failed to load HTTP server: $EVAL_ERROR");
    } else {
        $self->{server} = GLPI::Agent::HTTP::Server->new(%server_config);
        $self->{server}->init();
    }
}

sub ApplyServiceOptimizations {
    my ($self) = @_;

    # Preload all IDS databases to avoid reload them all the time during inventory
    my @planned = map { $_->plannedTasks() } $self->getTargets();
    if (grep { /^inventory$/i } @planned) {
        my %params = (
            logger  => $self->{logger},
            datadir => $self->{datadir}
        );
        getPCIDeviceVendor(%params);
        getUSBDeviceVendor(%params);
        getEDIDVendor(%params);
    }
}

sub RunningServiceOptimization {
    my ($self) = @_;
}

sub terminate {
    my ($self) = @_;

    # Handle forked processes
    $self->fork_exit();
    my $children = delete $self->{_fork};
    if ($children) {
        my @pids = keys(%{$children});
        foreach my $pid (@pids) {
            $self->child_exit($pid);
            kill 'TERM', $pid;
        }
    }

    # Still stop HTTP interface
    $self->{server}->stop() if ($self->{server});

    $self->{logger}->info("$PROVIDER Agent exiting ($$)")
        unless ($self->{current_task} || $self->forked());

    $self->SUPER::terminate();

    # Kill current forked task
    if ($self->{current_runtask}) {
        kill 'TERM', $self->{current_runtask};
        delete $self->{current_runtask};
    }

    # Remove pidfile
    unlink $self->{pidfile} if $self->{pidfile};
}

1;
