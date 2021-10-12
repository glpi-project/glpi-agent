package FusionInventory::Agent;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;
use File::Glob;
use IO::Handle;

use constant CONTINUE_WORD  => "...";

use FusionInventory::Agent::Version;
use FusionInventory::Agent::Config;
use FusionInventory::Agent::Logger;
use FusionInventory::Agent::Storage;
use FusionInventory::Agent::Target::Local;
use FusionInventory::Agent::Target::Server;
use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Hostname;
use FusionInventory::Agent::Tools::UUID;

our $VERSION = $FusionInventory::Agent::Version::VERSION;
my $PROVIDER = $FusionInventory::Agent::Version::PROVIDER;
our $COMMENTS = $FusionInventory::Agent::Version::COMMENTS || [];
our $VERSION_STRING = _versionString($VERSION);
our $AGENT_STRING = "$PROVIDER-Agent_v$VERSION";

sub _versionString {
    my ($VERSION) = @_;

    my $string = "$PROVIDER Agent ($VERSION)";
    if ($VERSION =~ /^\d+\.\d+\.(99\d\d|\d+-dev|.*-build-?\d+)$/) {
        unshift @{$COMMENTS}, "** THIS IS A DEVELOPMENT RELEASE **";
    }

    return $string;
}

sub new {
    my ($class, %params) = @_;

    my $self = {
        status  => 'unknown',
        datadir => $params{datadir},
        libdir  => $params{libdir},
        vardir  => $params{vardir},
        targets => [],
        _cache  => {},
    };
    bless $self, $class;

    return $self;
}

sub init {
    my ($self, %params) = @_;

    # Skip create object if still defined (re-init case)
    my $config = $self->{config} || FusionInventory::Agent::Config->new(
        options => $params{options},
        vardir  => $self->{vardir},
    );
    $self->{config} = $config;

    # Reset vardir if found in configuration
    $self->{vardir} = $self->{config}->{vardir}
        if $self->{config}->{vardir} && -d $self->{config}->{vardir};

    my $logger = FusionInventory::Agent::Logger->new(config => $config);
    $self->{logger} = $logger;

    $logger->debug("Configuration directory: ".$config->confdir());
    $logger->debug("Data directory: $self->{datadir}");
    $logger->debug("Storage directory: $self->{vardir}");
    $logger->debug("Lib directory: $self->{libdir}");

    $self->_handlePersistentState();

    # Persistent data can store a set "forcerun" value to be handled during start
    # Mainly used by win32 service installer
    my $forced_run = delete $self->{_forced_run};

    # Always reset targets to handle re-init case
    $self->{targets} = $config->getTargets(
        logger      => $self->{logger},
        deviceid    => $self->{deviceid},
        vardir      => $self->{vardir}
    );

    # Still handle --list-tasks case
    if (!$self->getTargets() && (!$params{options} || !$params{options}->{"list-tasks"})) {
        $logger->error("No target defined, aborting");
        exit 1;
    }

    # Keep program name for Provider inventory as it will be reset in setStatus()
    FusionInventory::Agent::Task::Inventory::Provider->require();
    $FusionInventory::Agent::Task::Inventory::Provider::PROGRAM = "$PROGRAM_NAME";

    # compute list of allowed tasks
    my $available = $self->getAvailableTasks();
    my @tasks = sort keys(%{$available});
    unless (@tasks) {
        $logger->error("No tasks available, aborting");
        exit 1;
    }

    # Keep available tasks as installed tasks for GLPI Agent protocol CONTACT
    $self->{installed_tasks} = [ map { lc($_) } @tasks ];

    my @plannedTasks = $self->computeTaskExecutionPlan($available);

    $logger->debug("Available tasks:");
    foreach my $task (@tasks) {
        $logger->debug("- $task: $available->{$task}");
    }

    foreach my $target ($self->getTargets()) {
        if ($target->isType('local') || $target->isType('server')) {
            $logger->debug("target $target->{id}: " . $target->getType() . " " . $target->getName());

            # Handle forced run request
            $target->setNextRunDateFromNow() if $forced_run;
        } else {
            $logger->debug("target $target->{id}: " . $target->getType());
        }

        # Register planned tasks by target
        my @planned = $target->plannedTasks(@plannedTasks);

        if (@planned) {
            $logger->debug("Planned tasks for $target->{id}: ".join(",",@planned));
        } else {
            $logger->debug("No planned task for $target->{id}");
        }
    }

    $logger->info("Options 'no-task' and 'tasks' are both used. Be careful that 'no-task' always excludes tasks.")
        if $config->hasFilledParam('no-task') && $config->hasFilledParam('tasks');

    # install signal handler to handle graceful exit
    $SIG{INT}  = sub { $self->terminate(); exit 0; };
    $SIG{TERM} = sub { $self->terminate(); exit 0; };

    if ($params{options}) {
        foreach my $comment (@{$COMMENTS}) {
            $self->{logger}->debug($comment);
        }
    }
}

sub run {
    my ($self) = @_;

    # API overrided in daemon or service mode

    $self->setStatus('waiting');

    my @targets = $self->getTargets();

    $self->{logger}->debug("Running in foreground mode");

    # foreground mode: check each targets once
    my $time = time();
    while ($self->getTargets() && @targets) {
        my $target = shift @targets;
        if ($self->{config}->{lazy} && $time < $target->getNextRunDate()) {
            if ($self->{config}->{force}) {
                $self->{logger}->info(
                    "$target->{id} is not ready yet, but run is forced"
                );
            } else {
                $self->{logger}->info(
                    "$target->{id} is not ready yet, next server contact " .
                    "planned for " . localtime($target->getNextRunDate())
                );
                next;
            }
        }

        eval {
            $self->runTarget($target);
        };
        $self->{logger}->error($EVAL_ERROR) if $EVAL_ERROR;

        # Reset next run date to support --lazy option with foreground mode
        $target->resetNextRunDate();
    }
}

sub terminate {
    my ($self) = @_;

    $self->{_terminate} = 1;

    # Forget our targets
    $self->{targets} = [];

    # Abort realtask running in that forked process or thread
    $self->{current_task}->abort()
        if ($self->{current_task});
}

sub runTarget {
    my ($self, $target) = @_;

    if ($target->isType('local') || $target->isType('server')) {
        $self->{logger}->info("target $target->{id}: " . $target->getType() . " " . $target->getName());
    }

    # the prolog/contact dialog must be done once for all tasks,
    # but only for server targets
    my $response;
    my $client;
    my @plannedTasks = $target->plannedTasks();
    if ($target->isGlpiServer()) {
        FusionInventory::Agent::HTTP::Client::GLPI->require();
        return $self->{logger}->error("GLPI Protocol library can't be loaded")
            if $EVAL_ERROR;

        $client = FusionInventory::Agent::HTTP::Client::GLPI->new(
            logger          => $self->{logger},
            timeout         => $self->{config}->{timeout},
            user            => $self->{config}->{user},
            password        => $self->{config}->{password},
            proxy           => $self->{config}->{proxy},
            ca_cert_file    => $self->{config}->{'ca-cert-file'},
            ca_cert_dir     => $self->{config}->{'ca-cert-dir'},
            no_ssl_check    => $self->{config}->{'no-ssl-check'},
            no_compress     => $self->{config}->{'no-compression'},
            ssl_cert_file   => $self->{config}->{'ssl-cert-file'},
            agentid         => uuid_to_string($self->{agentid}),
        );

        return $self->{logger}->error("Can't load GLPI Protocol CONTACT library")
            unless GLPI::Agent::Protocol::Contact->require();

        my %httpd_conf;
        # Add httpd-port & httpd-plugins status in contact request if possible
        if ($self->{server}) {
            $httpd_conf{"httpd-plugins"} = $self->{server}->plugins_list();
            $httpd_conf{"httpd-port"} = $self->{server}->{port};
        }

        my %enabled = map { lc($_) => 1 } @plannedTasks;
        my $contact = GLPI::Agent::Protocol::Contact->new(
            logger              => $self->{logger},
            deviceid            => $self->{deviceid},
            "installed-tasks"   => $self->{installed_tasks},
            "enabled-tasks"     => [ sort keys(%enabled) ],
            %httpd_conf
        );
        $contact->merge(tag => $self->{config}->{tag})
            if defined($self->{config}->{tag}) && length($self->{config}->{tag});

        $self->{logger}->info("sending contact request to $target->{id}");
        $response = $client->send(
            url     => $target->getUrl(),
            message => $contact,
        );
        unless ($response) {
            $self->{logger}->error("No answer from server at ".$target->getUrl());
            # Always fallback on legacy XML-based protocol on error
            $target->isGlpiServer('false');
            # Return true on net error
            return 1;
        }

        # Check we got a GLPI CONTACT answer
        if (ref($response) ne 'GLPI::Agent::Protocol::Contact') {
            $self->{logger}->info("$target->{id} is not understanding GLPI Agent protocol");
            $target->isGlpiServer('false');
            # return true to soon fallback on PROLOG request
            return 1;
        }

    } elsif ($target->isType('server')) {

        return unless FusionInventory::Agent::HTTP::Client::OCS->require();

        $client = FusionInventory::Agent::HTTP::Client::OCS->new(
            logger          => $self->{logger},
            timeout         => $self->{config}->{timeout},
            user            => $self->{config}->{user},
            password        => $self->{config}->{password},
            proxy           => $self->{config}->{proxy},
            ca_cert_file    => $self->{config}->{'ca-cert-file'},
            ca_cert_dir     => $self->{config}->{'ca-cert-dir'},
            no_ssl_check    => $self->{config}->{'no-ssl-check'},
            no_compress     => $self->{config}->{'no-compression'},
            ssl_cert_file   => $self->{config}->{'ssl-cert-file'},
            agentid         => uuid_to_string($self->{agentid}),
        );

        return unless FusionInventory::Agent::XML::Query::Prolog->require();

        my $prolog = FusionInventory::Agent::XML::Query::Prolog->new(
            deviceid => $self->{deviceid},
        );

        $self->{logger}->info("sending prolog request to $target->{id}");
        $response = $client->send(
            url     => $target->getUrl(),
            message => $prolog
        );
        unless ($response) {
            $self->{logger}->error("No answer from server at ".$target->getUrl());
            # Return true on net error
            return 1;
        }

        # Check if we got a GLPI server answer
        if (ref($response) eq 'GLPI::Agent::Protocol::Contact') {
            $self->{logger}->info("$target->{id} answer shows it supports GLPI Agent protocol");
            $target->isGlpiServer('true');
        } else {
            # update target
            my $content = $response->getContent();
            if (defined($content->{PROLOG_FREQ})) {
                $target->setMaxDelay($content->{PROLOG_FREQ} * 3600);
            }
        }
    }

    if ($target->isGlpiServer()) {
        # Handle contact answer including expiration and/or errors
        my $message = $response->get('message');
        my $status  = $response->status;

        if ($status eq 'error') {
            $self->{logger}->error(
                "server error: ".($message // "Server returned an error status")
            );
            return 0;
        } elsif ($status ne 'ok') {
            $self->{logger}->debug("unexpected server status: $status".
                ($message ? " ($message)" : "")
            );
            return 0;
        } elsif ($message) {
            $self->{logger}->debug("server message: $message");
        }

        $target->setMaxDelay($response->expiration) if $response->expiration;

        # Don't plan tasks disabled by server
        my $disabled = $response->get('disabled');
        if ($disabled) {
            if (ref($disabled) eq 'ARRAY' && @{$disabled}) {
                my %disabled = map { lc($_) => 1 } @{$disabled};
                # Never disable inventory if force option is used
                delete $disabled{inventory} if $self->{config}->{force};
                @plannedTasks = grep { ! exists($disabled{lc($_)}) } @plannedTasks;
            } elsif (!ref($disabled)) {
                $disabled = lc($disabled);
                # Only disable inventory if force option is not set
                if ($disabled ne "inventory" || !$self->{config}->{force}) {
                    @plannedTasks = grep {
                        lc($_) ne $disabled
                    } @plannedTasks;
                }
            }
        }

        my $tasks = $response->get("tasks");
        # Handle no-category set by server on inventory task
        if (ref($tasks) eq "HASH" && ref($tasks->{inventory}) eq 'HASH' && $tasks->{inventory}->{"no-category"}) {
            my $no_category = [ sort split(/,+/, $tasks->{inventory}->{"no-category"}) ];
            unless (@{$self->{config}->{"no-category"}} && join(",", sort @{$self->{config}->{"no-category"}}) eq join(",", @{$no_category})) {
                $self->{logger}->debug("set no-category configuration to: ".$tasks->{inventory}->{"no-category"});
                $self->{config}->{"no-category"} = $no_category;
            }
        }
    }

    foreach my $name (@plannedTasks) {
        eval {
            $self->runTask($target, $name, $response);
        };
        $self->{logger}->error($EVAL_ERROR) if $EVAL_ERROR;
        $self->setStatus($target->paused() ? 'paused' : 'waiting');

        # Leave earlier while requested
        last if $self->{_terminate};
        last if $target->paused();
    }

    return 0;
}

sub runTask {
    my ($self, $target, $name, $response) = @_;

    # API overrided in daemon or service mode

    $self->setStatus("running task $name");

    # standalone mode: run each task directly
    $self->runTaskReal($target, $name, $response);
}

sub runTaskReal {
    my ($self, $target, $name, $response) = @_;

    my $class = "FusionInventory::Agent::Task::$name";

    if (!$class->require()) {
        $self->{logger}->debug2("$name task module does not compile: $@")
            if $self->{logger};
        return;
    }

    my $task = $class->new(
        config       => $self->{config},
        datadir      => $self->{datadir},
        logger       => $self->{logger},
        event        => $self->{event},
        credentials  => $self->{credentials},
        target       => $target,
        deviceid     => $self->{deviceid},
        agentid      => uuid_to_string($self->{agentid}),
        cached_data  => $self->{_cache}->{$name},
    );

    # Handle init event and return
    if ($self->{event} && $self->{event}->{init}) {
        my $event = $task->newEvent();
        $target->addEvent($event) if $event;
        return;
    }

    return if $response && !$task->isEnabled($response);

    $self->{logger}->info("running task $name".($self->{event} ? ": $self->{event}->{name} event" : ""));
    $self->{current_task} = $task;

    $task->run(
        user            => $self->{config}->{user},
        password        => $self->{config}->{password},
        proxy           => $self->{config}->{proxy},
        ca_cert_file    => $self->{config}->{'ca-cert-file'},
        ca_cert_dir     => $self->{config}->{'ca-cert-dir'},
        no_ssl_check    => $self->{config}->{'no-ssl-check'},
        no_compress     => $self->{config}->{'no-compression'},
        ssl_cert_file   => $self->{config}->{'ssl-cert-file'},
    );

    # Try to cache data provided by the task if the next run can require it
    if ($task->keepcache() && ref($self) =~ /Daemon/) {
        my $cachedata = $task->cachedata();
        if (defined($cachedata) && GLPI::Agent::Protocol::Message->require()) {
            my $data = GLPI::Agent::Protocol::Message->new(message => $cachedata);
            $self->forked_process_event("AGENTCACHE,$name,".$data->getRawContent());
        }
    }

    # Try to handle task new event
    my $event = $task->event();
    if ($event && ref($self) =~ /Daemon/ && GLPI::Agent::Protocol::Message->require()) {
        my $message = GLPI::Agent::Protocol::Message->new(message => $event);
        $self->forked_process_event("TASKEVENT,$name,".$message->getRawContent());
    }

    delete $self->{current_task};
}

sub getStatus {
    my ($self) = @_;
    return $self->{status};
}

sub setStatus {
    my ($self, $status) = @_;

    my $config = $self->{config};

    # Rename process including status, for unix platforms
    $0 = lc($PROVIDER) . "-agent";
    $0 .= " (tag $config->{tag})" if $config->{tag};

    if ($status) {
        $self->{status} = $status;

        # Show set status in process name on unix platforms
        $0 .= ": $status";
    }
}

sub getTargets {
    my ($self) = @_;

    return @{$self->{targets}};
}

sub getAvailableTasks {
    my ($self) = @_;

    my $logger = $self->{logger};

    my %tasks;
    my %disabled  = map { lc($_) => 1 } @{$self->{config}->{'no-task'} // []};

    # tasks may be located only in agent libdir
    my $directory = $self->{libdir};
    $directory =~ s,\\,/,g;
    my $subdirectory = "FusionInventory/Agent/Task";
    # look for all Version perl modules around here
    foreach my $file (File::Glob::bsd_glob("$directory/$subdirectory/*/Version.pm")) {
        next unless $file =~ m{($subdirectory/(\S+)/Version\.pm)$};
        my $module = file2module($1);
        my $name = file2module($2);

        next if $disabled{lc($name)};

        my $version;
        if (!$module->require()) {
            $logger->debug2("module $module does not compile: $@") if $logger;

            # Don't keep trace of module, only really needed to fix perl 5.8 issue
            delete $INC{module2file($module)};

            next;
        }

        {
            no strict 'refs';  ## no critic
            $version = &{$module . '::VERSION'};
        }

        # no version means non-functionning task
        next unless $version;

        $tasks{$name} = $version;
        $logger->debug2("getAvailableTasks() : add of task $name version $version")
            if $logger;
    }

    return \%tasks;
}

sub _handlePersistentState {
    my ($self) = @_;

    # Only create storage at first call
    unless ($self->{storage}) {
        $self->{storage} = FusionInventory::Agent::Storage->new(
            logger    => $self->{logger},
            directory => $self->{vardir}
        );
    }

    # Load current agent state
    my $data = $self->{storage}->restore(name => "$PROVIDER-Agent");

    if (!$self->{deviceid} && !$data->{deviceid}) {
        # compute an unique agent identifier, based on host name and current time
        my $hostname = getHostname();

        my ($year, $month , $day, $hour, $min, $sec) =
            (localtime (time))[5, 4, 3, 2, 1, 0];

        $data->{deviceid} = sprintf "%s-%02d-%02d-%02d-%02d-%02d-%02d",
            $hostname, $year + 1900, $month + 1, $day, $hour, $min, $sec;
    } elsif (!$data->{deviceid}) {
        $data->{deviceid} = $self->{deviceid};
    }

    $self->{deviceid} = $data->{deviceid};

    # Support agentid
    if (!$self->{agentid} && !$data->{agentid}) {
        $data->{agentid} = create_uuid();
    } elsif (!$data->{deviceid}) {
        $data->{agentid} = $self->{agentid};
    }

    $self->{agentid} = $data->{agentid};

    # Handle the option to force a run during start/init/reinit if "forcerun" has
    # been set in storage datas
    $self->{_forced_run} = delete $data->{forcerun} || 0;

    # Always save agent state
    $self->{storage}->save(
        name => "$PROVIDER-Agent",
        data => $data
    );
}

sub setForceRun {
    my ($self, $forcerun) = @_;

    my $storage = FusionInventory::Agent::Storage->new(
        logger    => $self->{logger},
        directory => $self->{vardir}
    );

    my $data = $storage->restore(name => "$PROVIDER-Agent");

    $data->{forcerun} = defined($forcerun) ? $forcerun : 1;

    $storage->save(
        name => "$PROVIDER-Agent",
        data => $data
    );
}

sub computeTaskExecutionPlan {
    my ($self, $availableTasks) = @_;

    my $config = $self->{config};
    unless (defined($config) && ref($config) eq 'FusionInventory::Agent::Config') {
        $self->{logger}->error( "no config found in agent. Can't compute tasks execution plan" )
            if $self->{logger};
        return;
    }

    my @executionPlan;
    if ($config->hasFilledParam('tasks')) {
        $self->{logger}->debug2("Preparing execution plan") if defined($self->{logger});
        @executionPlan = _makeExecutionPlan($config->{'tasks'}, $availableTasks);
    } else {
        @executionPlan = keys(%{$availableTasks});
    }

    return @executionPlan;
}

sub _makeExecutionPlan {
    my ($sortedTasks, $availableTasks) = @_;

    my %tasks = map { lc($_) => $_ } keys(%{$availableTasks});

    my @executionPlan;
    foreach my $task (@{$sortedTasks}) {
        next unless $task;
        if ($task eq CONTINUE_WORD) {
            my %used  = map { $_ => 1 } @executionPlan;
            my @tasks = grep { ! $used{$_} } keys(%{$availableTasks});
            # we append all other available tasks
            push @executionPlan, @tasks if @tasks;
            last;
        }
        $task = lc($task);
        push @executionPlan, $tasks{$task}
            if exists($tasks{$task});
    }

    return @executionPlan;
}

1;
__END__

=head1 NAME

FusionInventory::Agent - FusionInventory agent

=head1 DESCRIPTION

This is the agent object.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<datadir>

the read-only data directory.

=item I<vardir>

the read-write data directory.

=item I<options>

the options to use.

=back

=head2 init()

Initialize the agent.

=head2 run()

Run the agent.

=head2 terminate()

Terminate the agent.

=head2 getStatus()

Get the current agent status.

=head2 setStatus()

Set new agent status, also updates process name on unix platforms.

=head2 getTargets()

Get all targets.

=head2 getAvailableTasks()

Get all available tasks found on the system, as a list of module / version
pairs:

%tasks = (
    'Foo' => x,
    'Bar' => y,
);

=head2 setForceRun($forcerun)

Set "forcerun" option to 1 (by default) in persistent state storage. This option
is only read during start, init or reinit. If set to true, the next run is planned
to be started as soon as possible.

=head1 LICENSE

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

See LICENSE file for details.
