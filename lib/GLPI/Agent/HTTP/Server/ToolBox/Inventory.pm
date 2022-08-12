package GLPI::Agent::HTTP::Server::ToolBox::Inventory;

use strict;
use warnings;

use threads;
use threads 'exit' => 'threads_only';
use threads::shared;

use parent "GLPI::Agent::HTTP::Server::ToolBox";

use English qw(-no_match_vars);
use UNIVERSAL::require;
use Encode qw(encode);
use HTML::Entities;
use Time::HiRes qw(gettimeofday usleep);
use Net::IP;

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;
use GLPI::Agent::Target;

use constant    inventory   => "inventory";

sub index {
    return inventory;
}

sub log_prefix {
    return "[toolbox plugin, inventory] ";
}

sub new {
    my ($class, %params) = @_;

    my ($name) = $class =~ /::(\w+)$/;

    my $self = {
        logger  => $params{toolbox}->{logger} ||
                    GLPI::Agent::Logger->new(),
        toolbox => $params{toolbox},
        name    => $name,
        tasks   => {},

        _scan   => 0,
        _local  => 0,
    };

    my $missingdep = 0;
    $missingdep = 1 unless GLPI::Agent::Task::NetDiscovery->require();
    $missingdep += 2 unless GLPI::Agent::Task::NetInventory->require();
    $self->{_missingdep} = $missingdep
        if $missingdep;

    bless $self, $class;

    return $self;
}

sub yaml_config_specs {
    my ($self, $yaml_config) = @_;

    return {
        inventory_navbar  => {
            category    => "Navigation bar",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'inventory_navbar'} || 1),
            text        => "Show Inventory in navigation bar",
            navbar      => "Inventory",
            link        => $self->index(),
            index       => 10, # index in navbar
        },
        threads_options  => {
            category    => "Network task",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "text" : "readonly",
            value       => $yaml_config->{'threads_options'} || '1|5|10|20|40',
            text        => "Network task threads number options",
            tips        => "threads number options separated by pipes,\nfirst value used as default threads\n(default=1|5|10|20|40)",
        },
        timeout_options  => {
            category    => "Network task",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "text" : "readonly",
            value       => $yaml_config->{'timeout_options'} || '1|10|30|60',
            text        => "Network task SNMP timeout options",
            tips        => "SNMP timeout options separated by pipes,\nfirst value used as default timeout\n(default=1|10|30|60)",
        },
        networktask_save  => {
            category    => "Network task",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "text" : "readonly",
            value       => $yaml_config->{'networktask_save'} || '.',
            text        => "Base folder to save XML",
            tips        => "Base folder may be relative to the agent folder",
        },
        inventory_tags  => {
            category    => "Inventories",
            type        => "text",
            value       => $yaml_config->{'inventory_tags'} || '',
            text        => "List of tags",
            tips        => "Tags separated by commas\nYou can use it to separate inventory files by site",
        },
    };
}

sub update_template_hash {
    my ($self, $hash) = @_;

    return unless $hash;

    my $yaml = $self->yaml() || {};
    my $yaml_config = $yaml->{configuration} || {};

    # Update Text::Template HASH but protect some values by encoding html entities
    foreach my $base (qw(ip_range)) {
        $hash->{$base} = {};
        next unless $yaml->{$base};
        foreach my $name (keys(%{$yaml->{$base}})) {
            my $entry = $yaml->{$base}->{$name};
            foreach my $key (qw(name ip_start ip_end)) {
                my $value = $entry->{$key};
                next unless defined($value);
                $value = encode('UTF-8', encode_entities($value))
                    if $key =~ /^name$/;
                $hash->{$base}->{$name}->{$key} = $value;
            }
        }
    }

    # Set missing deps
    $hash->{missingdeps} = $self->{_missingdep} // '';

    # Set running task
    $hash->{outputid} = $self->{taskid} || '';
    $hash->{set_range} = $self->{taskid} && $self->{tasks}->{$self->{taskid}}
        ? encode('UTF-8', encode_entities($self->{tasks}->{$self->{taskid}}->{ip_range} || '')) : '';
    $hash->{tasks} = $self->{tasks} || {};
    $hash->{verbosity} = $self->{verbosity} || 'debug';
    my @threads_option = grep { /^\d+$/ } split(/[|]/,$yaml_config->{threads_options} || '1|5|10|20|40');
    $hash->{threads_options} = [ sort { $a <=> $b } keys(%{{map { $_ => 1 } @threads_option}}) ];
    $self->{threads_default} = $threads_option[0] || 1;
    $hash->{threads_option} = $self->get_from_session('netscan_threads_option') || $self->{threads_default};
    my @timeout_options = grep { /^\d+$/ } split(/[|]/,$yaml_config->{timeout_options} || '1|10|30|60');
    $hash->{timeout_options} = [ sort { $a <=> $b } keys(%{{map { $_ => 1 } @timeout_options}}) ];
    $self->{timeout_default} = $hash->{timeout_options}->[0] || 1;
    $hash->{timeout_option} = $self->get_from_session('netscan_timeout_option') || $self->{timeout_default};
    my @tag_options = split(/[,]+/,$yaml_config->{inventory_tags} || '');
    $hash->{tag_options} = \@tag_options;
    $hash->{current_tag} = $self->get_from_session('inventory_tag');
    $hash->{title} = "Inventory";
}

my %handlers = (
    'submit/localinventory' => \&_submit_localinventory,
    'submit/netscan'        => \&_submit_netscan,
);

sub event_logger {
    my ($self) = @_;

    # We always set verbosity higher to debug2 so we can analyse any debug level
    # messages.
    my $logger = GLPI::Agent::Logger->new( verbosity => 2 );

    # Hack logger to add ourself as backend so our addMessage callback is always
    # called on logging message in any thread
    push @{$logger->{backends}}, $self;

    # Set logger as shared thread
    $self->{_event_logger_lock} = 0;
    share($self->{_event_logger_lock});

    return $logger;
}

# To use ourself as a logger backend in a multi-threaded process
sub addMessage {
    my ($self, %params) = @_;

    return unless $params{level} && $params{message};

    my $agent = $self->{toolbox}->{server}->{agent};

    my $taskid = $self->{taskid};
    if ($agent->forked()) {
        lock($self->{_event_logger_lock});
        $agent->forked_process_event("LOGGER,$taskid,[$params{level}] $params{message}");
    } else {
        my $messages = $self->{tasks}->{$taskid}->{messages};
        push @{$messages}, "[$params{level}] $params{message}";
    }
}

sub _submit_netscan {
    my ($self, $form, $yaml) = @_;

    return $self->errors("No IP range selected")
        unless $form->{'input/ip_range'};

    my $ip_range = $yaml->{ip_range} || {};
    return $self->errors("No such IP range")
        unless $ip_range->{$form->{'input/ip_range'}};

    return $self->netscan($form->{'input/ip_range'});
}

sub netscan {
    my ($self, $ip_range_name, $ip) = @_;

    return $self->errors(
        $self->{_missingdep} == 1 ? "netdiscovery task is not installed" :
        $self->{_missingdep} == 2 ? "netdiscovery task is not installed" :
            "netdiscovery and netinventory tasks are not installed"
    )
        if $self->{_missingdep};

    my $ip_range = $self->yaml('ip_range') || {};
    $ip_range = $ip_range->{$ip_range_name}
        or return;

    my $procname = "network scan";
    my ($running) = grep {
        $_->{procname} eq $procname && $_->{done} == 0 &&
        $_->{ip_range} eq $ip_range_name && !$_->{aborted} &&
        (!$_->{ip} || $_->{ip} eq $ip || !$ip)
    } values(%{$self->{tasks}});
    return $self->errors("A $procname is still running for an IP on that range: $ip, ".$running->{name})
        if ($running && $ip && $running->{ip});
    return $self->errors("A $procname is still running for that IP range: ".$running->{name})
        if $running;

    my $agent = $self->{toolbox}->{server}->{agent};

    my $yaml_config = $self->yaml('configuration') || {};

    # Generate a taskid an associate it the task
    my $taskid = $self->_task_id();
    $self->{tasks}->{$taskid} = {
        messages    => [],
        index       => 0,
        procname    => $procname,
        done        => 0,
        ip_range    => $ip_range_name,
        name        => 'scan'.$self->{_scan}++,
        time        => time,
        ip          => $ip,
    };
    my $task = $self->{tasks}->{$taskid};
    $self->{taskid} = $taskid;

    # Compute credentials
    my @credentials = ();
    my $credentials = $self->yaml('credentials') || {};
    foreach my $credential (@{$ip_range->{credentials} || []}) {
        my $cred = $credentials->{$credential}
            or return $self->errors("No such credentials: $credential");
        return $self->errors("Missing version on credentials: ".($cred->{name}||$credential))
            unless defined($cred->{snmpversion});
        my $CRED = {
            # brackets are here cosmetic for task logs and will be filtered in
            # GLPI::Agent::HTTP::Server::ToolBox::Results::NetDiscovery
            ID      => "[$credential]",
            VERSION =>
                $cred->{snmpversion} eq 'v1'  ? '1'  :
                $cred->{snmpversion} eq 'v2c' ? '2c' :
                $cred->{snmpversion} eq 'v3'  ? '3'  : '1',
        };
        if ($cred->{snmpversion} =~ /^v1|v2c$/) {
            $CRED->{COMMUNITY} = $cred->{community} || "public";
        } elsif ($cred->{snmpversion} eq 'v3') {
            $CRED->{USERNAME} = $cred->{username}
                or return $self->errors("Missing username on credentials: ".($cred->{name}||$credential));
            $CRED->{AUTHPASSWORD} = $cred->{authpassword} || '';
            $CRED->{AUTHPROTOCOL} = $cred->{authprotocol} || '';
            $CRED->{PRIVPASSWORD} = $cred->{privpassword} || '';
            $CRED->{PRIVPROTOCOL} = $cred->{privprotocol} || '';
        }
        push @credentials, $CRED;
    }

    # From here we can continue in a forked process
    return $taskid if $agent->fork(
        name        => $procname,
        description => "$task->{name} $procname request",
        id          => "$taskid",
    );

    my $logger = $self->event_logger();
    my $starttime = gettimeofday();
    $logger->info("Scanning $ip_range_name range as $task->{name} $procname task...");

    # Set default credentials to public v1 & public v2c if none set
    push @credentials, {
        ID => 1, VERSION => "1", COMMUNITY => 'public'
    }, {
        ID => 2, VERSION => "2c", COMMUNITY => 'public'
    } unless @credentials;

    # Create an NetDiscovery task
    my $netdisco = GLPI::Agent::Task::NetDiscovery->new(
        config       => $agent->{config},
        datadir      => $agent->{datadir},
        logger       => $logger,
        target       => GLPI::Agent::Task::NetInventory::Target->new(),
        deviceid     => $agent->{deviceid},
    );
    # Set client logger
    $netdisco->{client} = GLPI::Agent::Task::NetDiscovery::Client->new(
        logger      => $logger,
        save        => $yaml_config->{networktask_save} || '.',
        timeout     => $self->get_from_session('netscan_timeout_option') || $self->{timeout_default},
        credentials => \@credentials,
        tag         => $self->get_from_session('inventory_tag'),
        ip_range    => $ip_range_name,
    );

    # Compute ranges
    my @ranges = ();
    my $RANGE = {
        IPSTART  => $ip || $ip_range->{ip_start},
        IPEND    => $ip || $ip_range->{ip_end},
        #PORT     => $ip_range->{port},
        #PROTOCOL => $ip_range->{protocol},
    };
    $RANGE->{ENTITY} = $ip_range->{entities_id}
        if defined($ip_range->{entities_id});
    $RANGE->{ID} = $ip_range->{id}
        if defined($ip_range->{id});
    push @ranges, $RANGE;

    # Add job to task
    GLPI::Agent::Task::NetDiscovery::Job->require();
    push @{$netdisco->{jobs}}, GLPI::Agent::Task::NetDiscovery::Job->new(
        logger => $logger,
        params => {
            PID               => 1,
            THREADS_DISCOVERY => $self->get_from_session('netscan_threads_option') || $self->{threads_default},
            TIMEOUT           => $self->get_from_session('netscan_timeout_option') || $self->{timeout_default},
        },
        ranges => \@ranges,
        credentials => \@credentials
    );

    $logger->info("Running $task->{name} task...");
    $netdisco->{target_expiration} = $ip ? 300 : 60;
    $netdisco->run();
    my $chrono = sprintf("%0.3f", gettimeofday() - $starttime);
    $logger->info("$task->{name}: $ip_range_name $procname done");
    $logger->debug("Task run in $chrono seconds");
    $agent->forked_process_event("DONE,$taskid");
    $agent->fork_exit();
}

sub _submit_localinventory {
    my ($self, $form, $yaml) = @_;

    my $procname = "local inventory";
    return $self->errors("A $procname is still running")
        if grep {
            $_->{procname} eq $procname && $_->{done} == 0 && !$_->{aborted}
        } values(%{$self->{tasks}});

    my $yaml_config = $yaml->{configuration} || {};

    # Generate a taskid an associate it the task
    my $taskid = $self->_task_id();
    $self->{tasks}->{$taskid} = {
        messages    => [],
        index       => 0,
        procname    => $procname,
        done        => 0,
        name        => 'local'.$self->{_local}++,
        time        => time,
        found       => 1,
        islocal     => 1,
        inventory_count => 0,
    };
    my $task = $self->{tasks}->{$taskid};
    $self->{taskid} = $taskid;

    # From here we can continue in a forked process
    my $agent = $self->{toolbox}->{server}->{agent};
    return if $agent->fork(
        name        => $procname,
        description => "$procname request",
        id          => $taskid,
    );

    # Set agent tag if set for the plugin
    $agent->{config}->{tag} = $self->get_from_session('inventory_tag');

    my $logger = $self->event_logger();
    my $starttime = gettimeofday();
    $logger->info("Running $task->{name} task...");

    my $path = !$yaml_config->{networktask_save} || $yaml_config->{networktask_save} eq '.' ?
        "inventory" : $yaml_config->{networktask_save}."/inventory";

    # Create a local target and update it to run now
    GLPI::Agent::Target::Local->require();
    my $local = GLPI::Agent::Target::Local->new(
        logger     => $logger,
        delaytime  => 1,
        basevardir => $agent->{vardir},
        path       => $path
    );

    # Make sure path exists as folder
    mkdir $path unless -d $path;

    # Create an Inventory task
    GLPI::Agent::Task::Inventory->require();
    my $inventory = GLPI::Agent::Task::Inventory->new(
        config       => $agent->{config},
        datadir      => $agent->{datadir},
        logger       => $logger,
        target       => $local,
        deviceid     => $agent->{deviceid},
    );

    # Report modules count to prepare progress bar handling (we don't count
    # Module & Version sub modules)
    my $modules_count = scalar($inventory->getModules())-2;
    $logger->debug("Inventory modules found: $modules_count");

    $inventory->run();
    my $chrono = sprintf("%0.3f", gettimeofday() - $starttime);
    $logger->info("$task->{name}: $procname done");
    $logger->debug("Task run in $chrono seconds");
    $agent->forked_process_event("DONE,$taskid");
    $agent->fork_exit();
}

sub _task_id {
    my ($self) = @_;
    my $taskid = join("-", map { unpack("h4", pack("I", int(rand(65536)))) } 1..4);
    return $self->{tasks}->{$taskid} ? $self->_task_id() : $taskid;
}

sub register_events_cb {
    return 1;
}

sub events_cb {
    my ($self, $event) = @_;

    return unless defined($event);

    if ($event =~ /^LOGGER,([^,]*),(.*)$/) {
        my $taskid = $1;
        return unless $self->{tasks}->{$taskid};
        my $msg = encode('UTF-8', $2);
        push @{$self->{tasks}->{$taskid}->{messages}}, $msg;
        $self->_analyse_event($taskid, $2);
    } elsif ($event =~ /^DONE,(.*)$/) {
        my $taskid = $1;
        return unless $self->{tasks}->{$taskid};
        $self->{tasks}->{$taskid}->{done} = 1;
    } else {
        return 0;
    }

    # Return true as we handled the event
    return 1;
}

sub _analyse_event {
    my ($self, $taskid, $event) = @_;

    return unless $taskid && $event;

    my $task = $self->{tasks}->{$taskid}
        or return;

    if ($event =~ /^\[debug\] scanning block (.*)$/) {
        my $block = Net::IP->new($1);
        my $count = 0;
        do {
            $count++;
        } while (++$block);
        $task->{maxcount} = $count;
    } elsif ($event =~ /^\[debug\] creating (\d+) worker threads/) {
        $task->{maxthreads} = int($1) unless $task->{maxthreads};
    } elsif ($event =~ /^\[debug\] \[thread (\d+)\] creation$/) {
        $task->{threads}->{int($1)} = 0
            if keys(%{$task->{threads}}) < $task->{maxthreads};
    } elsif ($event =~ /\[thread (\d+)\] #(\d+), scanning ([0-9a-f.:]+)/) {
        my $th = int($1);
        my $scan = $task->{threads}->{$th};
        if (defined($scan)) {
            $task->{unknown}++
                if $scan && !$task->{snmp}->[$scan] && !$task->{ping}->[$scan] && !$task->{arp}->[$scan];
            $task->{count}++ if $task->{threads}->{$th};
            $task->{threads}->{$th} = int($2);
        }
    } elsif ($event =~ /\[thread (\d+)\] termination/) {
        my $scan = $task->{threads}->{int($1)};
        $task->{count}++ if $scan;
        $task->{unknown}++
            if $scan && !$task->{snmp}->[$scan] && !$task->{ping}->[$scan] && !$task->{arp}->[$scan];
    } elsif ($event =~ /\[thread (\d+)\] #(\d+), - scanning .* with SNMP, .*: (.*)/) {
        $task->{snmp}->[int($2)] = $3 eq 'success'
            unless $task->{snmp} && $task->{snmp}->[int($2)];
    } elsif ($event =~ /\[thread (\d+)\] #(\d+), - scanning .* with .* ping: (.*)/) {
        $task->{ping}->[int($2)] = $3 eq 'success'
            unless $task->{ping} && $task->{ping}->[int($2)];
        _update_others($task);
    } elsif ($event =~ /\[thread (\d+)\] #(\d+), - scanning .* in arp table: (.*)/) {
        $task->{arp}->[int($2)] = $3 eq 'success';
        _update_others($task);
    } elsif ($event =~ /\[thread (\d+)\] .* Saving .* discovery infos as XML.../) {
        my $scan = $task->{threads}->{int($1)};
        $task->{snmp_support}++ if $scan && $task->{snmp}->[$scan];
        $self->update_results();
    } elsif ($event =~ /Saving .* inventory infos as XML.../) {
        $task->{inventory_count}++;
        $self->update_results();
    } elsif ($event =~ /network (inventory|discovery).* done/) {
        delete $task->{snmp};
        delete $task->{ping};
        delete $task->{arp};
        delete $task->{threads};
        delete $task->{maxthreads};
        # Guaranty to set progress bar at 100%
        $task->{count} = $task->{maxcount};
    } elsif ($event =~ /local inventory done/) {
        $task->{inventory_count}++;
        # Guaranty to set progress bar at 100%
        $task->{count} = $task->{maxcount};
        $self->update_results();
    } elsif ($event =~ /\[debug\] Inventory modules found: (\d+)$/) {
        $task->{maxcount} = int($1);
    } elsif ($event =~ /\[debug2\] module \S+ disabled$/) {
        $task->{maxcount}--;
    } elsif ($event =~ /\[debug2\]   \S+ disabled: implicit dependency \S+ not enabled$/) {
        $task->{maxcount}--;
    } elsif ($event =~ /\[debug\] module \S+ disabled because of \S+$/) {
        $task->{maxcount}--;
    } elsif ($event =~ /\[debug\] module \S+ disabled: failure to load/) {
        $task->{maxcount}--;
    } elsif ($event =~ /\[debug\] Running (.+)$/) {
        if ($task->{current_module}) {
            $task->{count}++;
        }
        $task->{current_module} = $1;
    } elsif ($event =~ /\[warning\] Aborting net(discovery|inventory) task/) {
        $task->{aborted} = 1;
    }

    # Percent for progress bar
    $task->{percent} = $task->{maxcount} && $task->{count} ?
        int($task->{count}/$task->{maxcount}*100) : 0;
}

sub _update_others {
    my ($task) = @_;

    my $max = $task->{count} || 0;
    my $others = 0;
    foreach my $i (1..$max) {
        next if $task->{snmp} && $task->{snmp}->[$i];
        $others++ if (($task->{ping} && $task->{ping}->[$i]) || ($task->{arp} && $task->{arp}->[$i]));
    }
    $task->{others_support} = $others;
}

sub ajax_support {
    return 1;
}

sub ajax {
    my ($self, $query) = @_;

    my %query = ( debug => 1 );
    if ($query) {
        $self->debug2("Got inventory ajax query: $query");
        foreach my $params (split(/&/, $query)) {
            if ($params =~ /^([a-z]+)=(.*)$/) {
                $query{$1} = $2;
            } else {
                $query{$params} = 1;
            }
        }
    }

    my $taskid = $query{'id'}
        or return;

    my $task = $self->{tasks}->{$taskid}
        or return;

    my $filter_qr = qr/^\[(?:error|info|warning|debug)\]/;
    $filter_qr = qr/^\[(?:error|info|warning)\]/ if $query{'info'};
    $filter_qr = 0 if $query{'debug2'};

    # Set default taskid for current page
    $self->{taskid} = $taskid;

    my %headers  = (
        'Content-Type'          => 'text/plain',
        'X-Inventory-Output'    => 'partial',
        'X-Inventory-Status'    => 'running',
        'X-Inventory-Count'     => $task->{inventory_count} || 0,
        'X-Inventory-Percent'   => $task->{percent} || 0,
        'X-Inventory-Task'      => $taskid,
        # Client should close ajax related connection as we don't expect to
        # answer another request in the same connection
        'Connection'            => 'close',
    );

    if ($task->{islocal}) {
        $headers{'X-Inventory-IsLocal'} = $task->{islocal};
    } else {
        $headers{'X-Inventory-With-SNMP'} = $task->{snmp_support} if $task->{snmp_support};
        $headers{'X-Inventory-With-Others'} = $task->{others_support} if $task->{others_support};
        $headers{'X-Inventory-Scanned'} = $task->{count} if $task->{count};
        $headers{'X-Inventory-Unknown'} = $task->{unknown} if $task->{unknown};
        $headers{'X-Inventory-MaxCount'} = $task->{maxcount} if $task->{maxcount};
    }

    my $agent = $self->{toolbox}->{server}->{agent};
    if ($task->{done} || !$agent->forked(name => $task->{procname})) {
        $headers{'X-Inventory-Status'} = 'done';
    }
    if ($query{'what'} && $query{'what'} eq 'full') {
        $headers{'X-Inventory-Output'} = 'full';
        $task->{index} = 0;
    }
    if ($query{'what'} && $query{'what'} eq 'abort' && (!$task->{percent} || $task->{percent}<100)) {
        $self->debug2("Abort request for: $task->{name}");
        $agent->abort_child($taskid);
        $task->{aborted} = 1;
    }
    $headers{'X-Inventory-Status'} = 'aborted'
        if $task->{aborted};

    my $message = '';
    # index should be read first from request to support multi-users acces on the
    # same task output
    my $index = $query{index} || $task->{index};
    while ($index < @{$task->{messages}}) {
        my $lf = $index ? "\n" : "";
        my $this = $task->{messages}->[$index++];
        $message .= $lf . $this if !$filter_qr || $this =~ $filter_qr;
    }
    $task->{index} = $index;
    $headers{'X-Inventory-Index'} = $index;

    # For some reasons, first ajax response should not be empty...
    $message = '...' unless $index || $message;

    return 200, 'OK', \%headers, $message;
}

sub handle_form {
    my ($self, $form) = @_;

    return unless $form && $form->{form} && $form->{form} =~ /^inventory$/;

    my $yaml = $self->yaml() || {};
    my $yaml_config = $yaml->{configuration} || {};

    # Only handle inventory if the inventory navbar is enabled (by default)
    return unless !exists($yaml_config->{'inventory_navbar'}) || $self->isyes($yaml_config->{'inventory_navbar'});

    $self->{verbosity} =  $form->{'input/verbose'}
        && $form->{'input/verbose'} =~ /^info|debug|debug2$/ ?
            $form->{'input/verbose'} : 'debug' ;

    my $options_threads = $yaml_config->{'threads_options'} || '1|5|10|20|40';
    if ($options_threads && $form->{'input/threads'}) {
        my $threads = $form->{'input/threads'} =~ m/^$options_threads$/ ? int($form->{'input/threads'}) : 1 ;
        $self->store_in_session( 'netscan_threads_option' => $threads );
    }

    my $options_timeout = $yaml_config->{'timeout_options'} || '1|10|30|60';
    if ($options_timeout && $form->{'input/timeout'}) {
        my $timeout = $form->{'input/timeout'} =~ m/^$options_timeout$/ ? int($form->{'input/timeout'}) : 1;
        $self->store_in_session( 'netscan_timeout_option' => $timeout );
    }

    my $tag_options = $yaml_config->{'inventory_tags'} || '';
    if (length($tag_options) && defined($form->{'input/tag'}) && length($form->{'input/tag'})) {
        $self->store_in_session( 'inventory_tag' => $form->{'input/tag'} )
            if grep { $form->{'input/tag'} eq $_ } split(/,/, $tag_options);
    } else {
        $self->delete_in_session('inventory_tag');
    }
    if (defined($form->{'input/newtag'}) && length($form->{'input/newtag'})) {
        my %tag_options = map { $_ => 1 } split(/,/, $tag_options);
        $self->store_in_session( 'inventory_tag' => $form->{'input/newtag'} );
        # Add new tag to tags options list
        unless ($tag_options{$form->{'input/newtag'}}) {
            $tag_options .= "," if (defined($tag_options) && length($tag_options));
            $tag_options .= $form->{'input/newtag'};
            $yaml_config->{'inventory_tags'} = $tag_options;
            $self->need_save("configuration");
            $self->yaml({ configuration => $yaml_config });
            $self->write_yaml();
        }
    }

    foreach my $handler (keys(%handlers)) {
        if (exists($form->{$handler})) {
            $self->debug2("Handling form as $handler");
            &{$handlers{$handler}}($self, $form, $yaml);
            last;
        }
    }
}

## no critic (ProhibitMultiplePackages)
package
    GLPI::Agent::Task::NetDiscovery::Client;

use threads;

use English qw(-no_match_vars);
use UNIVERSAL::require;
use Encode qw(encode);
use HTML::Entities;

sub new {
    my ($class, %params) = @_;

    return bless {
        logger      => $params{logger},
        save        => $params{save},
        timeout     => $params{timeout},
        credentials => $params{credentials},
        tag         => $params{tag},
        ip_range    => $params{ip_range},
    }, $class;
}

sub netdiscovery { 1 }

sub ip {}

sub mac {}

sub send {
    my ($self, %params) = @_;

    my $devices = $params{message}->{h}->{CONTENT}->{DEVICE};
    my $device  = ref($devices) eq 'ARRAY' ? $devices->[0] :
                  ref($devices) eq 'HASH'  ? $devices      : undef;
    return unless $device;

    # Set ip range in XML as device attribute so we can use handle rescan request
    $device->{"-ip_range"} = encode('UTF-8', encode_entities($self->{ip_range})) if $self->{ip_range};
    my $authsnmp = $device->{AUTHSNMP};
    $device->{AUTHSNMP} = encode('UTF-8', encode_entities($authsnmp));

    my $ip  = $device ? $device->{IP} || $self->ip() : undef;
    # Set MAC from discovery if not seen by NetInventory
    $device->{INFO}->{MAC} = $self->mac
        if (!$self->netdiscovery() && $device->{INFO} && !$device->{INFO}->{MAC} && $self->mac);
    my $xml = $params{message}->getContent();

    if ($self->{save} && $device) {
        die "No ip given with device\n" unless $ip;
        my $tag = defined($self->{tag}) && length($self->{tag}) ? "_".$self->{tag} : "";
        # Skip the case where only a wrong arp entry was seen, in that case, ARP node
        # exists but is set to undef. In case of just ping, MAC node is missing.
        if ($self->netdiscovery()) {
            $self->{logger}->info("Saving $ip discovery infos as XML...");
            _writeXml($self->{save} . "/netdiscovery", $ip.$tag.".xml", $xml);
        } else {
            if ($device->{ERROR}) {
                my $message = $device->{ERROR}->{MESSAGE};
                $self->{logger}->error("Inventory failed on $message");
                $self->{logger}->error("Check your credentials") if $message =~ /timeout/;
            } else {
                $self->{logger}->info("Saving $ip inventory infos as XML...");
                _writeXml($self->{save} . "/netinventory", $ip.$tag.".xml", $xml);
            }
        }
    } else {
        print $xml;
    }

    if ($self->netdiscovery() && $device) {
        die "No ip given with device\n" unless $ip;

        unless ($device->{AUTHSNMP}) {
            $self->{logger}->info("Skipping inventory for $ip on no SNMP response");
            return;
        }

        unless ($device->{TYPE}) {
            $self->{logger}->info("Skipping inventory for $ip on not recognized device type");
            return;
        }

        GLPI::Agent::Task::NetInventory->require();
        GLPI::Agent::Task::NetInventory::Job->require();

        my $inventory = GLPI::Agent::Task::NetInventory->new(
            target => GLPI::Agent::Task::NetInventory::Target->new(),
            logger => $self->{logger}
        );

        # Multi-threading still set on NetDiscovery task and we are only
        # requesting one device scan
        $inventory->{jobs} = [
            GLPI::Agent::Task::NetInventory::Job->new(
                params => {
                    PID           => 1,
                    THREADS_QUERY => 1,
                    TIMEOUT       => 60,
                },
                devices     => [{
                    ID           => 0,
                    IP           => $ip,
                    #~ PORT         => $options->{port},
                    #~ PROTOCOL     => $options->{protocol},
                    AUTHSNMP_ID  => $authsnmp,
                }],
                credentials => $self->{credentials},
            )
        ];

        $inventory->{client} = GLPI::Agent::Task::NetInventory::Client->new(
            logger      => $self->{logger},
            ip          => $ip,
            mac         => $device->{MAC},
            save        => $self->{save},
            tag         => $self->{tag},
        );

        $inventory->run();
    }
}

sub _writeXml {
    my ($folder, $file, $xml) = @_;

    mkdir $folder unless -d $folder;

    die "Can't create $folder directory: $!\n" unless -d $folder;

    my $fh;
    if (open($fh,">", "$folder/$file")) {
        print $fh $xml;
        close($fh);
    } else {
        die "Failed to write '$folder/$file': $!\n";
    }
}

package
    GLPI::Agent::Task::NetInventory::Target;

sub new {
    my ($class, %params) = @_;

    return bless {}, $class;
}

sub getUrl {
    my ($self, %params) = @_;

    ## no critic (ExplicitReturnUndef)
    return undef;
}

package
    GLPI::Agent::Task::NetInventory::Client;

use parent -norequire, 'GLPI::Agent::Task::NetDiscovery::Client';

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    $self->{_ip} = $params{ip};
    $self->{_mac} = $params{mac};

    return bless $self, $class;
}

sub netdiscovery { 0 }

sub ip {
    my ($self) = @_;
    return $self->{_ip};
}

sub mac {
    my ($self) = @_;
    return $self->{_mac};
}

1;
