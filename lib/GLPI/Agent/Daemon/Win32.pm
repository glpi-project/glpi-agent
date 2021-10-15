package GLPI::Agent::Daemon::Win32;

use strict;
use warnings;

use threads;
use threads 'exit' => 'threads_only';

use File::Spec;
use Cwd qw(abs_path);
use Time::HiRes qw(usleep);

use constant SERVICE_USLEEP_TIME => 200_000; # in microseconds

use Win32;
use Win32::Daemon;

use GLPI::Agent::Version;
use GLPI::Agent::Logger;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Win32;

use parent qw(GLPI::Agent::Daemon);

my $PROVIDER = $GLPI::Agent::Version::PROVIDER;

sub SERVICE_NAME        { lc($PROVIDER) . "-agent"; }
sub SERVICE_DISPLAYNAME { "$PROVIDER Agent"; }

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    $self->{last_state} = SERVICE_START_PENDING;

    bless $self, $class;

    return $self;
}

sub name  {
    my ($self, $name) = @_;

    $self->{_name} = $name if $name;

    return $self->{_name} || SERVICE_NAME;
}

sub displayname  {
    my ($self, $displayname) = @_;

    $self->{_displayname} = $displayname if $displayname;

    return $self->{_displayname} || SERVICE_DISPLAYNAME;
}

sub RegisterService {
    my ($self, %options) = @_;

    my $libdir = $options{libdir} || $self->{libdir} ;
    my $params = '"' . $options{program} . '"';

    # Try to compute libdir from this module file if still not absolute
    $libdir = abs_path(File::Spec->rel2abs('../../../../..', __FILE__))
        unless ($libdir && File::Spec->file_name_is_absolute($libdir) && -d $libdir);

    # Add path to lib if setup
    $params = '-I"' . $libdir . '" ' . $params
        if ($libdir && -d $libdir);

    my $service = {
        name       => $self->name( $options{name} ),
        display    => $self->displayname( $options{displayname} ),
        path       => "$^X",
        parameters => $params
    };

    if (!Win32::Daemon::CreateService($service)) {
        my $lasterr = Win32::Daemon::GetLastError();
        if ($lasterr == 1073) {
            warn "Service still registered\n";

        } elsif ($lasterr == 1072) {
            warn "Service marked for deletion.\n" .
                "Computer must be rebooted to register the same service name\n";
            return 1;

        } else {
            my $error = Win32::FormatMessage($lasterr);
            warn "Service not registered: $lasterr: $error\n";
            return 2;
        }
    }

    return 0;
}

sub DeleteService {
    my ($self, %options) = @_;

    if (!Win32::Daemon::DeleteService("",$self->name( $options{name} ))) {
        my $lasterr = Win32::Daemon::GetLastError();
        if ($lasterr == 1060) {
            warn "Service not found\n";

        } elsif ($lasterr == 1072) {
            warn "Service still marked for deletion. Computer must be rebooted\n";
            return 1;

        } else {
            my $error = Win32::FormatMessage($lasterr);
            warn "Service not removed $lasterr: $error\n";
            return 2;
        }
    }

    return 0;
}

sub StartService {
    my ($self) = @_;

    Win32::Daemon::StartService();

    my $timer = time;
    my $lastQuery = 0;

    my $State = Win32::Daemon::State();

    # Wait until service control manager is ready
    while ($State == SERVICE_NOT_READY) {
        usleep( SERVICE_USLEEP_TIME );
        $State = Win32::Daemon::State();
    }

    $State = Win32::Daemon::State( SERVICE_START_PENDING );

    $self->{last_state} = $State;
    while ( SERVICE_STOPPED != $State) {
        if ( SERVICE_START_PENDING == $State ) {
            $self->_start_agent();
        } elsif ( SERVICE_STOP_PENDING == $State ) {
            $self->_stop_agent();
            last;
        } elsif ( SERVICE_PAUSE_PENDING == $State ) {
            if ($State != $self->{last_state} || time-$timer >= 10) {
                if ($self->{agent_thread} && $self->{agent_thread}->is_running()) {
                    $self->{agent_thread}->kill('SIGSTOP');
                } else {
                    $self->{last_state} = SERVICE_STOP_PENDING;
                }
                $timer = time;
            }
            my @targets = $self->getTargets();
            if ( scalar(grep { $_->paused() } @targets) == @targets ) {
                $self->{last_state} = SERVICE_PAUSED;
                $self->ApplyServiceOptimizations();
            } else {
                $self->{last_state} = SERVICE_PAUSE_PENDING;
            }
        } elsif ( SERVICE_CONTINUE_PENDING == $State ) {
            if ($State != $self->{last_state} || time-$timer >= 10) {
                if ($self->{agent_thread} && $self->{agent_thread}->is_running()) {
                    $self->{agent_thread}->kill('SIGCONT');
                } else {
                    $self->{last_state} = SERVICE_STOP_PENDING;
                }
                $timer = time;
            }
            my @targets = $self->getTargets();
            if ( scalar(grep { $_->paused() } @targets) == 0 ) {
                $self->{last_state} = SERVICE_RUNNING;
            } else {
                $self->{last_state} = SERVICE_CONTINUE_PENDING;
            }
        } elsif ( SERVICE_PAUSED == $State ) {
            $self->{last_state} = $self->{agent_thread} &&
                $self->{agent_thread}->is_running() ?
                    SERVICE_PAUSED : SERVICE_STOP_PENDING ;
        } elsif ( SERVICE_RUNNING == $State ) {
            $self->{last_state} = $self->{agent_thread} &&
                $self->{agent_thread}->is_running() ?
                    SERVICE_RUNNING : SERVICE_STOP_PENDING ;
        }

        my $Query = Win32::Daemon::QueryLastMessage();
        if ( $Query == SERVICE_CONTROL_INTERROGATE ) {
            Win32::Daemon::State( $self->{last_state} );
        } elsif ($Query != $lastQuery && $Query != 0xFFFFFFFF) {
            $lastQuery = $Query;
        }

        if ( time-$timer >= 10 || $self->{last_state} != $State ) {
            Win32::Daemon::State( $self->{last_state}, 10000 );
            $timer = time;
        }
        usleep( SERVICE_USLEEP_TIME );
        $State = Win32::Daemon::State();
    }

    Win32::Daemon::State(SERVICE_STOPPED);
    Win32::Daemon::StopService();
}

sub AcceptedControls {
    my ($self, $controls) = @_;

    $controls = SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN | SERVICE_ACCEPT_PAUSE_CONTINUE
        unless $controls;

    Win32::Daemon::AcceptedControls($controls);
}

sub _retrieveServiceName {
    my ($self) = @_;

    my $service = getCurrentService();
    if ($service) {
        $self->name($service->{Name});
        $self->displayname($service->{DisplayName});
    }
}

sub _start_agent {
    my ($self) = @_;

    # Start service dedicated thread only if required
    unless (defined($self->{agent_thread})) {

        # Start agent in a dedicated thread
        $self->{agent_thread} = threads->create(sub {
            # First start a thread dedicated to Win32::OLE calls
            $self->{worker_thread} = GLPI::Agent::Tools::Win32::start_Win32_OLE_Worker();

            # Set service name after the worker thread has been started
            $self->_retrieveServiceName();

            # We may want to permit the service to restart itself after one day
            $self->{_service_safetime} = time + 86400;

            $self->init(options => { service => 1 });

            # install signal handler to handle pause/continue signals
            $SIG{STOP} = sub { $self->Pause(); };
            $SIG{CONT} = sub { $self->Continue(); };

            $self->run();
        });
    }

    Win32::Daemon::State(SERVICE_RUNNING);
}

sub _stop_agent {
    my ($self) = @_;

    my $timer = time-1;
    my $tries = 10;

    while ( $self->{agent_thread} ) {
        if ($self->{agent_thread}->is_running() && time-$timer >= 1) {
            $self->{agent_thread}->kill('SIGINT');
            Win32::Daemon::State(SERVICE_STOP_PENDING, $tries * 1000);
            if (!$tries-- && !$self->{agent_thread}->is_detached()) {
                $self->{agent_thread}->detach();
                last;
            }
            $timer = time;

        } elsif ($self->{agent_thread}->is_joinable()) {
            $self->{agent_thread}->join();
            last;
        }
        usleep( SERVICE_USLEEP_TIME );
    }

    delete $self->{agent_thread};
}

sub Pause {
    my ($self) = @_;

    # Abort task thread if running
    if ($self->{task_thread} && $self->{task_thread}->is_running()) {
        $self->{task_thread}->kill('SIGINT')->detach();
        delete $self->{task_thread};
    }

    foreach my $target ($self->getTargets()) {
        $target->pause();
    }

    $self->setStatus('paused');

    # We don't want to permit the service to restart itself when paused
    delete $self->{_service_safetime};

    $self->{logger}->info("$PROVIDER Agent paused") if $self->{logger};
}

sub Continue {
    my ($self) = @_;

    $self->setStatus('waiting');

    foreach my $target ($self->getTargets()) {
        $target->continue();
    }

    # We may want to permit the service to restart itself after one day
    $self->{_service_safetime} = time + 86400;

    $self->{logger}->info("$PROVIDER Agent resumed") if $self->{logger};
}

sub ApplyServiceOptimizations {
    my ($self) = @_;

    # Setup worker Logger after service Logger
    GLPI::Agent::Tools::Win32::setupWorkerLogger(config => $self->{config});

    $self->SUPER::ApplyServiceOptimizations();

    # Win32 only service optimization

    # Preload is64bit result to avoid a lot of WMI calls
    is64bit();

    # Also call running service optimization to free memory
    $self->RunningServiceOptimization();
}

sub RunningServiceOptimization {
    my ($self) = @_;

    return if $self->{_optimization_rundate} && time < $self->{_optimization_rundate};

    # win32 platform needs optimization
    if ($self->{logger} && $self->{logger}->debug_level()) {
        my ($WorkingSetSize, $PageFileUsage) = getAgentMemorySize();
        # WSS=Working Set Size - PFU=Page File Usage
        $self->{logger}->debug("Agent memory usage before freeing memory: WSS=$WorkingSetSize PFU=$PageFileUsage")
            unless $WorkingSetSize < 0;
    }

    # Make working set memory available for the system
    FreeAgentMem();

    my ($WorkingSetSize, $PageFileUsage) = getAgentMemorySize();
    if ($self->{logger} && $WorkingSetSize > 0) {
        $self->{logger}->info("$PROVIDER Agent memory usage: WSS=$WorkingSetSize PFU=$PageFileUsage");
    }

    # Initialize a max PageFileUsage the first time we need to optimize
    $self->{_MaxPageFileUsage} = 2*$PageFileUsage unless $self->{_MaxPageFileUsage};

    # Check if it's time to restart ourself
    if ($self->{_service_safetime} && $PageFileUsage > $self->{_MaxPageFileUsage} && time > $self->{_service_safetime}) {
        $self->{_service_safetime} += 3600;
        $self->{logger}->info("Restarting myself as ".$self->displayname()." service");
        my $restart = 'start /b "" cmd /S /C "net stop '.$self->name().' && net start '.$self->name().'" >nul';
        system($restart);
    }

    # Avoid to run service optimization too often
    $self->{_optimization_rundate} = time + 60;
}

sub terminate {
    my ($self) = @_;

    # Abort task thread if running
    if ($self->{task_thread} && $self->{task_thread}->is_running()) {
        $self->{task_thread}->kill('SIGINT')->detach();
        delete $self->{task_thread};
    }

    # Abort Win32::OLE worker thread if running
    if ($self->{worker_thread} && $self->{worker_thread}->is_running()) {
        $self->{worker_thread}->kill('SIGKILL')->detach();
        delete $self->{worker_thread};
    }

    $self->SUPER::terminate();

    threads->exit();
}

sub runTask {
    my ($self, $target, $name, $response) = @_;

    $self->setStatus("running task $name");

    # service mode: run each task in a dedicated thread

    $self->{task_thread} = threads->create(sub {
        # We don't handle HTTPD interface in this thread
        delete $self->{server};

         my $tid = threads->tid;

        # install signal handler to handle STOP/INT/TERM signals
        $SIG{STOP} = $SIG{INT} = $SIG{TERM} = sub {
            $self->{logger}->debug("aborting thread $tid which was handling task $name");
            threads->exit();
        };

        $self->{logger}->debug("new thread $tid to handle task $name");

        $self->runTaskReal($target, $name, $response);

        threads->exit();
    });

    while ( $self->{task_thread} ) {
        if ($self->{task_thread}->is_joinable()) {
            $self->{task_thread}->join();
            my $thread = delete $self->{task_thread};
            undef $thread;
        }
        $self->sleep(1);
    }
}

1;
