package GLPI::Agent::HTTP::Server::ToolBox::Inventory;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox";

use English qw(-no_match_vars);
use UNIVERSAL::require;
use Encode qw(decode encode);
use HTML::Entities;
use URI::Escape;
use Time::HiRes qw(gettimeofday usleep);
use Net::IP;

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;
use GLPI::Agent::Target;

use constant    inventory   => "inventory";
use constant    jobs        => "jobs";

use constant    need_init   => 1;

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

sub init {
    my ($self) = @_;

    return unless $self->read_yaml();

    $self->_load_jobs();
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
    my $jobs = $self->yaml(jobs) || {};
    my $ip_range = $self->yaml('ip_range') || {};
    my $yaml_config = $self->yaml('configuration') || {};

    # Update Text::Template HASH but protect some values by encoding html entities
    foreach my $base (qw(ip_range jobs scheduling)) {
        $hash->{$base} = {};
        next unless $yaml->{$base};
        foreach my $name (keys(%{$yaml->{$base}})) {
            my $entry = $yaml->{$base}->{$name};
            foreach my $key (keys(%{$entry})) {
                my $value = $entry->{$key};
                next unless defined($value);
                if ($key =~ /^name|ip_range|description$/) {
                    $value = encode('UTF-8', encode_entities($value));
                } elsif ($key =~ /^enabled$/) {
                    $value = $self->isyes($value);
                }
                $hash->{$base}->{$name}->{$key} = $value;
            }
        }
    }

    # Don't include listing datas when editing
    unless ($self->edit()) {
        $hash->{columns} = [
            [ name          => "Task name"     ],
            [ type          => "Type"          ],
            [ scheduling    => "Scheduling"    ],
            [ last_run_date => "Last run date" ],
            [ next_run_date => "Next run date" ],
            [ config        => "Configuration" ],
            [ description   => "Description"   ]
        ];
        $hash->{order} = $self->get_from_session('jobs_order') || "ascend";
        my $asc = $hash->{order} eq 'ascend';
        my $ordering = $hash->{ordering_column} = $self->get_from_session('jobs_ordering_column') || 'name';
        $hash->{jobs_order} = [
            sort {
                my ($A, $B) =  $asc ? ( $a, $b ) : ( $b, $a );
                if ($ordering eq 'name') {
                    $A cmp $B
                } elsif ($ordering eq 'last_run_date') {
                    ($jobs->{$A}->{$ordering} || 0) <=> ($jobs->{$B}->{$ordering} || 0) || $A cmp $B
                } elsif ($ordering eq 'next_run_date') {
                    my ($A1, $B1) = ($jobs->{$A}->{$ordering} || 0, $jobs->{$B}->{$ordering} || 0);
                    unless ($self->isyes($jobs->{$A}->{enabled})) {
                        $A1 = $jobs->{$A}->{last_run_date} || 0;
                    }
                    unless ($self->isyes($jobs->{$B}->{enabled})) {
                        $B1 = $jobs->{$B}->{last_run_date} || 0;
                    }
                    $A1 <=> $B1 || $A cmp $B
                } elsif ($ordering eq 'scheduling') {
                    ($jobs->{$A}->{$ordering} && $jobs->{$A}->{$ordering}->[0] || '') cmp ($jobs->{$B}->{$ordering} && $jobs->{$B}->{$ordering}->[0] || '') || $A cmp $B
                } elsif ($ordering eq 'config') {
                    ($jobs->{$A}->{$ordering} && $jobs->{$A}->{$ordering}->{target} || '') cmp ($jobs->{$B}->{$ordering} && $jobs->{$B}->{$ordering}->{target} || '') || $A cmp $B
                } else {
                    ($jobs->{$A}->{$ordering} || '') cmp ($jobs->{$B}->{$ordering} || '') || $A cmp $B
                }
            } keys(%{$jobs})
        ];
        my @display_options = grep { /^\d+$/ } split(/[|]/,$yaml_config->{display_options} || '30|0|5|10|20|40|50|100|500');
        $hash->{display_options} = [ sort { $a <=> $b } keys(%{{map { $_ => 1 } @display_options}}) ];
        my $display = $self->get_from_session('display');
        $hash->{display} = length($display) ? $display : $display_options[0];
        $hash->{iprange_options} = [ sort { $a cmp $b } map { encode('UTF-8', encode_entities($_)) } keys(%{$ip_range}) ];
    }

    # Set missing deps
    $hash->{missingdeps} = $self->{_missingdep} // '';

    # Set known targets
    my $agent = $self->{toolbox}->{server}->{agent};
    $self->{targets} = $hash->{targets} = {};
    foreach my $target ($agent->getTargets()) {
        next if $target->isType('listener');
        my $id = $target->id()
            or next;
        $hash->{targets}->{$id} = [ $target->getType(), $target->getName() ];
    }
    # Default target when creating a new task
    $hash->{default_target} = $hash->{targets}->{server0} ? 'server0' : '';

    # Set running task
    $hash->{outputid} = $self->{taskid} || '';
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
    'submit/add'            => \&_submit_add,
    'submit/cancel'         => \&_submit_cancel,
    'submit/update'         => \&_submit_update,
    'submit/delete'         => \&_submit_delete,
    'submit/disable'        => \&_submit_disable,
    'submit/enable'         => \&_submit_enable,
    'submit/run-now'        => \&_submit_runnow,
    'submit/rename'         => \&_submit_rename,
    'submit/newtag'         => \&_submit_newtag,
);

sub _submit_rename {
    my ($self, $form, $yaml) = @_;

    return unless $form;

    my $jobs = $yaml->{jobs} || {};

    my $edit = $self->edit();
    my $newname = $form->{'input/new-name'};

    # Do nothing if no new was provided
    return unless defined($newname) && length($newname);

    # Do nothing if nothing to rename
    return unless defined($edit) && length($edit);

    # Do nothing if name is the same
    return if $newname eq $form->{'edit'};

    if (exists($jobs->{$newname})) {
        $newname = encode('UTF-8', $newname);
        return $self->errors("Rename task: An entry still exists with that name: '$newname'");
    }

    unless (exists($jobs->{$edit})) {
        $edit = encode('UTF-8', $edit);
        return $self->errors("Rename task: No such task: '$edit'");
    }

    $jobs->{$newname} = delete $jobs->{$edit};
    $self->need_save(jobs);
    $self->edit($newname);
}

sub _submit_newtag {
    my ($self, $form, $yaml) = @_;

    return unless $form;

    my $jobs = $yaml->{jobs} || {};

    my $edit = $self->edit();
    my $newtag = $form->{'input/newtag'};

    # Do nothing if no new tag was provided
    return unless defined($newtag) && length($newtag);

    my $job = $jobs->{$edit}
        or return;

    return unless $job->{type} && $job->{type} eq 'local';

    $job->{config}->{tag} = $newtag;
    $self->need_save(jobs);
}

sub _submit_cancel {
    my ($self, $form) = @_;

    return unless $form;

    $self->reset_edit();
    delete $form->{empty};
}

sub _submit_add {
    my ($self, $form, $yaml) = @_;

    return unless $form;

    my $jobs = $yaml->{jobs} || {};

    # Validate input/name before updating
    my $name = $form->{'input/name'};
    if ($name && exists($jobs->{$name})) {
        $name = encode('UTF-8', $name);
        return $self->errors("New task: An entry still exists with that name: '$name'");
    }
    if ($form->{'input/name'}) {
        # Validate form
        my $type = $form->{"input/type"};
        return $self->errors("New task: Unsupported task type")
            unless $type =~ /^local|netscan$/;
        my $enabled = $self->yesno($form->{"input/enabled"});
        my $job = {
            enabled     => $enabled,
            type        => $type,
        };
        my $target = $form->{"input/target"};
        return $self->errors("New task: Unsupported target")
            if $target && !exists($self->{targets}->{$target});
        $job->{config}->{target} = $target
            if $target;
        $job->{config}->{tag} = $form->{"input/tag"}
            if $form->{"input/tag"};
        if ($type eq 'netscan') {
            my $ipranges = $yaml->{ip_range} || {};
            my $iprange = $form->{'add-iprange'}
                or return $self->errors("New task: No IP range selected");
            my @ipranges = map { decode('UTF-8', uri_unescape($_)) } split('&', $iprange)
                or return $self->errors("New task: No IP range selected");
            @ipranges = grep { exists($ipranges->{$_}) } @ipranges
                or return $self->errors("New task: No IP range selected");
            $job->{config}->{ip_range} = [ sort @ipranges ];
            my $threads = int($form->{"input/threads"} || $self->{threads_default});
            $job->{config}->{threads} = $threads;
            my $timeout = int($form->{"input/timeout"}) || 1;
            $job->{config}->{timeout} = $timeout;
        }
        return $self->errors("New task: Scheduling type is mandatory")
            unless $form->{"input/scheduling/type"};
        return $self->errors("New task: Unsupported scheduling type")
            unless $form->{"input/scheduling/type"} =~ /^delay|timeslot$/;
        my $scheduling = $yaml->{scheduling} || {};
        if ($form->{"input/scheduling/type"} eq 'delay') {
            return $self->errors("New task: No such scheduling")
                unless $form->{"input/delay"} && $scheduling->{$form->{"input/delay"}};
            $job->{scheduling} = [ $form->{"input/delay"} ];
        } else {
            return $self->errors("New task: No scheduling selected")
                unless $form->{"input/timeslot"} && $form->{"set-timeslot"};
            return $self->errors("New task: No such scheduling")
                unless $scheduling->{$form->{"input/timeslot"}};
            my @timeslots = map { decode('UTF-8', uri_unescape($_)) } split('&', $form->{"set-timeslot"});
            return $self->errors("New task: No such scheduling")
                if grep { ! $scheduling->{$_} } @timeslots;
            $job->{scheduling} = \@timeslots;
        }
        $job->{description} = $form->{"input/description"} if $form->{"input/description"};
        $jobs->{$name} = $job;
        $self->need_save(jobs);
        delete $form->{empty};
    } elsif (!$name) {
        $self->errors("New task: Can't create entry without name") if $form->{empty};
        # We should return an empty add form
        $form->{empty} = 1;
    }
}

sub _submit_update {
    my ($self, $form, $yaml) = @_;

    return unless $form;

    my $jobs = $yaml->{jobs} || {};
    my $edit = $self->edit();
    my $job = $jobs->{$edit};

    if ($job) {
        # Validate form
        my $type = $form->{"input/type"};
        return $self->errors("Update task: Unsupported task type")
            unless $type =~ /^local|netscan$/;
        if ($job->{type} ne $type) {
            $job->{type} = $type;
            $self->need_save(jobs);
        }

        if (defined($form->{"input/enabled"})) {
            my $enabled = $self->yesno($form->{"input/enabled"});
            if ($job->{enabled} ne $enabled) {
                $job->{enabled} = $enabled;
                $self->need_save(jobs);
            }
        }

        my $target = $form->{"input/target"};
        return $self->errors("Update task: Unsupported target")
            if $target && !exists($self->{targets}->{$target});
        if ($target && (!$job->{config}->{target} || $job->{config}->{target} ne $target)) {
            $job->{config}->{target} = $target;
            $self->need_save(jobs);
        } elsif (!$target && $job->{config}->{target}) {
            delete $job->{config}->{target};
            $self->need_save(jobs);
        }

        my $tag = $form->{"input/tag"};
        if (!$tag && exists($job->{config}->{tag})) {
            delete $job->{config}->{tag};
            $self->need_save(jobs);
        } elsif ($tag && (!exists($job->{config}->{tag}) || $job->{config}->{tag} ne $tag)) {
            $job->{config}->{tag} = $tag;
            $self->need_save(jobs);
        }

        if ($type eq 'netscan') {
            my $ipranges = $yaml->{ip_range} || {};
            my @ipranges = map { m{^checkbox/ip_range/(.*)$} } grep { /^checkbox\/ip_range\// && $form->{$_} eq 'on' } keys(%{$form});
            return $self->errors("Update task: No IP range selected")
                unless @ipranges;
            my %previous = map { $_ => 1 } @{$job->{config} ? $job->{config}->{ip_range} // [] : []};
            my $new = 0;
            my %newconfig = ();
            foreach my $iprange (@ipranges) {
                return $self->errors("Update task: No such IP range")
                    unless $ipranges->{$iprange};
                $newconfig{$iprange} = 1;
                $new++ unless $previous{$iprange};
                delete $previous{$iprange};
            }
            # We have a new config if new iprange has been added or if one from previous has not been kept
            if ($new || keys(%previous)) {
                $job->{config}->{ip_range} = [ sort keys(%newconfig) ];
                $self->need_save(jobs);
            }
            my $threads = int($form->{"input/threads"});
            if ($threads > 0 && (!$job->{config} || !$job->{config}->{threads} || int($job->{config}->{threads}) != $threads)) {
                $job->{config}->{threads} = $threads;
                $self->need_save(jobs);
            }
            my $timeout = int($form->{"input/timeout"});
            if ($timeout > 0 && (!$job->{config} || !$job->{config}->{timeout} || int($job->{config}->{timeout}) != $timeout)) {
                $job->{config}->{timeout} = $timeout;
                $self->need_save(jobs);
            }
        }

        return $self->errors("Update task: Scheduling type is mandatory")
            unless $form->{"input/scheduling/type"};
        return $self->errors("Update task: Unsupported scheduling type")
            unless $form->{"input/scheduling/type"} =~ /^delay|timeslot$/;
        my $scheduling = $yaml->{scheduling} || {};
        if ($form->{"input/scheduling/type"} eq 'delay') {
            return $self->errors("Update task: No such scheduling")
                unless $form->{"input/delay"} && $scheduling->{$form->{"input/delay"}};
            $job->{scheduling} = [ $form->{"input/delay"} ];
        } else {
            return $self->errors("Update task: No scheduling selected")
                unless $form->{"input/timeslot"} && $form->{"set-timeslot"};
            return $self->errors("Update task: No such scheduling")
                unless $scheduling->{$form->{"input/timeslot"}};
            my @timeslots = map { decode('UTF-8', uri_unescape($_)) } split('&', $form->{"set-timeslot"});
            return $self->errors("Update task: No such scheduling")
                if grep { ! $scheduling->{$_} } @timeslots;
            $job->{scheduling} = \@timeslots;
        }

        my $description = $form->{"input/description"};
        if (defined($description)) {
            if (!length($description)) {
                delete $job->{description};
                $self->need_save(jobs);
            } elsif (!defined($job->{description}) || $job->{description} ne $description) {
                $job->{description} = $description;
                $self->need_save(jobs);
            }
        }
    } else {
        $self->errors("Update task: No such task: '$edit'");
        $self->reset_edit();
    }
}

sub _submit_delete {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $jobs = $yaml->{jobs} || {};
    my @selected = map { m{^checkbox/(.*)$} } grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});
    foreach my $name (@selected) {
        my $job = $jobs->{$name}
            or next;
        if ($self->isyes($job->{enabled})) {
            $self->errors(sprintf("Update task: Can't delete enabled task: &laquo;&nbsp;%s&nbsp;&raquo;", encode('UTF-8', $name)));
            next;
        }
        delete $jobs->{$name};
        $self->need_save(jobs);
    }
}

sub _submit_disable {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $jobs = $yaml->{jobs} || {};
    my @selected = map { m{^checkbox/(.*)$} } grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});
    foreach my $name (@selected) {
        next unless $jobs->{$name};
        $jobs->{$name}->{enabled} = $self->yesno('no');
        $self->need_save(jobs);
    }
}

sub _submit_enable {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $jobs = $yaml->{jobs} || {};
    my @selected = map { m{^checkbox/(.*)$} } grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});
    foreach my $name (@selected) {
        next unless $jobs->{$name};
        $jobs->{$name}->{enabled} = $self->yesno('yes');
        $self->need_save(jobs);
    }
}

sub _submit_runnow {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $jobs = $yaml->{jobs} || {};
    my @selected = map { m{^checkbox/(.*)$} } grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});
    foreach my $name (@selected) {
        my $job = $jobs->{$name}
            or next;
        unless ($job->{type}) {
            $self->warning(sprintf("Task has no type: &laquo;&nbsp;%s&nbsp;&raquo;", encode('UTF-8', $name)));
            next;
        }
        my $config = $job->{config} // {};
        if ($job->{type} eq 'local') {
            # Recycle taskid
            my ($taskid) = grep { $self->{tasks}->{$_}->{name} eq $name && $self->{tasks}->{$_}->{islocal} } keys(%{$self->{tasks}});
            $self->_run_local($config->{tag}, $yaml, $name, $taskid, $config->{target});
            next if $self->errors();
        } elsif ($job->{type} eq 'netscan') {
            # Recycle taskid
            my ($taskid) = grep { $self->{tasks}->{$_}->{name} eq $name && !$self->{tasks}->{$_}->{islocal} } keys(%{$self->{tasks}});
            $self->netscan($name, $taskid);
        } else {
            $self->warning(sprintf("Task has not a supported type: &laquo;&nbsp;%s&nbsp;&raquo;", encode('UTF-8', $name)));
            next;
        }
        # Change scalar type to integer to be stored as integer in YAML
        $job->{last_run_date} = int(time);
        $self->need_save(jobs);

        # We need to reschedule event if enabled
        if ($self->isyes($job->{enabled})) {
            my $event = $self->{toolbox}->{target}->getEvent($name);
            # To find next run date, we need to reset not_before time by setting it to now/last_run_date
            my $rundate = $self->_get_next_run_date($name, $job, $job->{last_run_date});
            $event->rundate($rundate);
            $job->{next_run_date} = $rundate;
            # Re-schedule event
            $self->{toolbox}->{target}->delEvent($event);
            $self->{toolbox}->{target}->addEvent($event);
        }
    }
}

sub event_logger {
    my ($self) = @_;

    # We always set verbosity higher to debug2 so we can analyse any debug level
    # messages.
    my $logger = GLPI::Agent::Logger->new( verbosity => 2 );

    # Hack logger to add ourself as backend so our addMessage callback is always
    # called on logging message in any thread
    push @{$logger->{backends}}, $self;

    return $logger;
}

# To use ourself as a logger backend in a multi-threaded process
sub addMessage {
    my ($self, %params) = @_;

    return unless $params{level} && $params{message};

    my $agent = $self->{toolbox}->{server}->{agent};

    my $taskid = $self->{taskid};
    if ($agent->forked()) {
        $agent->forked_process_event("LOGGER,$taskid,[$params{level}] $params{message}");
    } else {
        my $messages = $self->{tasks}->{$taskid}->{messages};
        push @{$messages}, "[$params{level}] $params{message}";
    }
}

sub netscan {
    my ($self, $name, $ip_ranges, $ip, $taskid) = @_;

    return $self->errors(
        $self->{_missingdep} == 1 ? "netdiscovery task is not installed" :
        $self->{_missingdep} == 2 ? "netdiscovery task is not installed" :
            "netdiscovery and netinventory tasks are not installed"
    )
        if $self->{_missingdep};

    my $jobs = $name ? $self->yaml('jobs') : {};
    my $job = $name && $jobs ? $jobs->{$name} : {};

    $ip_ranges = $job->{config}->{ip_range} || []
        if !$ip_ranges && $name && $job && $job->{config};

    my $ip_range = $self->yaml('ip_range') || {};
    my @ip_ranges = grep { exists($ip_range->{$_}) } @{$ip_ranges}
        or return;

    my $procname = "network scan";
    my ($running) = grep {
        $_->{procname} eq $procname && $_->{done} == 0 && !$_->{aborted} &&
        (($name && $_->{name} eq $name) || (@{$ip_ranges} == 1 && grep { $ip_ranges->[0] eq $_ } @{$_->{ip_ranges}}))
        && (!$_->{ip} || $_->{ip} eq $ip || !$ip)
    } values(%{$self->{tasks}});
    return $self->errors("A $procname is still running for an IP on that range: $ip, ".$running->{name})
        if ($running && $ip && $running->{ip});
    return $self->errors("A $procname is still running for that IP range: ".$running->{name})
        if $running;

    my $agent = $self->{toolbox}->{server}->{agent};

    my $yaml_config = $self->yaml('configuration') || {};

    # Generate a taskid if necessary
    $taskid = $self->_task_id()
        unless $taskid;
    $self->{tasks}->{$taskid} = {
        messages    => [],
        index       => 0,
        procname    => $procname,
        done        => 0,
        ip_ranges   => $ip_ranges,
        name        => $name || 'scan'.$self->{_scan}++,
        time        => time,
        ip          => $ip,
    };
    my $task = $self->{tasks}->{$taskid};
    $self->{taskid} = $taskid;

    # Compute credentials
    my @credentials = ();
    my %credentials = ();
    my $credentials = $self->yaml('credentials') || {};
    foreach my $range (@ip_ranges) {
        my $range_cred = $ip_range->{$range}->{credentials}
            or next;
        foreach my $credential (@{$range_cred}) {
            my $CRED;
            my $cred = $credentials->{$credential}
                or return $self->errors("No such credentials: $credential");
            if (!defined($cred->{type}) || $cred->{type} eq 'snmp') {
                return $self->errors("Missing version on credentials: ".($cred->{name}||$credential))
                    unless defined($cred->{snmpversion});
                $CRED = {
                    TYPE    => 'snmp',
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
                # Add port set on credential if not default one
                $CRED->{PORT}     = $cred->{port} if defined($cred->{port}) && int($cred->{port}) != 161;
                # Add protocol set on credential if it's not the default
                $CRED->{PROTOCOL} = $cred->{protocol} if $cred->{protocol} && $cred->{protocol} ne 'udp';
            }
            if ($CRED) {
                if ($name) {
                    push @{$credentials{$range}}, $CRED;
                } else {
                    push @credentials, $CRED;
                }
            } else {
                $self->{logger}->debug("Credential $credential of type $cred->{type} not used");
            }
        }
    }

    # From here we can continue in a forked process
    return $taskid if $agent->fork(
        name        => $procname,
        description => "$task->{name} $procname request",
        id          => "$taskid",
    );

    my $logger = $self->event_logger();
    my $starttime = gettimeofday();
    if ($name) {
        $logger->info("Starting $name $procname task job...");
    } else {
        $logger->info("Scanning $ip_ranges->[0] range as $task->{name} $procname task...");
    }

    # Set default credentials to public v1 & public v2c if none set
    push @credentials, {
        ID => 1, VERSION => "1", COMMUNITY => 'public'
    }, {
        ID => 2, VERSION => "2c", COMMUNITY => 'public'
    } unless @credentials || keys(%credentials);

    # Create an NetDiscovery task
    my $netdisco = GLPI::Agent::Task::NetDiscovery->new(
        config       => $agent->{config},
        datadir      => $agent->{datadir},
        logger       => $logger,
        target       => GLPI::Agent::Target::Local->new(
            path       => $yaml_config->{networktask_save} // '.',
            basevardir => $agent->{vardir},
        ),
        deviceid     => $agent->{deviceid},
    );

    # Compute ranges
    my @ranges = ();
    foreach my $range (@ip_ranges) {
        my $RANGE = {
            NAME    => $range,
            IPSTART => $ip || $ip_range->{$range}->{ip_start},
            IPEND   => $ip || $ip_range->{$range}->{ip_end},
        };
        $RANGE->{ENTITY} = $ip_range->{$range}->{entities_id}
            if defined($ip_range->{$range}->{entities_id});
        $RANGE->{ID} = $ip_range->{$range}->{id}
            if defined($ip_range->{$range}->{id});
        push @ranges, $RANGE;
    }

    # Support threads & timeout job configuration or get them from current session
    my ($threads, $timeout);
    if ($name && $job && $job->{config}) {
        $threads = $job->{config}->{threads};
        $timeout = $job->{config}->{timeout};
    } else {
        $threads = $self->get_from_session('netscan_threads_option');
        $timeout = $self->get_from_session('netscan_timeout_option');
    }

    # Add job to task
    GLPI::Agent::Task::NetDiscovery::Job->require();
    push @{$netdisco->{jobs}}, GLPI::Agent::Task::NetDiscovery::Job->new(
        logger => $logger,
        params => {
            PID               => 1,
            THREADS_DISCOVERY => $threads || $self->{threads_default},
            TIMEOUT           => $timeout || $self->{timeout_default},
        },
        ip_range => $ip_ranges,
        netscan => 1,
        ranges => \@ranges,
        credentials => @credentials ? \@credentials : \%credentials
    );

    $logger->info("Running $task->{name} task...");
    $netdisco->{target_expiration} = $ip ? 300 : 60;
    $netdisco->run();
    my $chrono = sprintf("%0.3f", gettimeofday() - $starttime);
    $logger->info("$task->{name}: ".($name || $ip_ranges->[0])." $procname done");
    $logger->debug("Task run in $chrono seconds");
    $agent->forked_process_event("DONE,$taskid");
    $agent->fork_exit();
}

sub _run_local {
    my ($self, $tag, $yaml, $name, $taskid, $targetid) = @_;

    my $procname = "local inventory";
    return $self->errors("A $procname is still running")
        if grep {
            $_->{procname} eq $procname && $_->{done} == 0 && !$_->{aborted}
        } values(%{$self->{tasks}});

    my $yaml_config = $yaml->{configuration} || {};

    # Generate a taskid if necessary
    $taskid = $self->_task_id()
        unless $taskid;
    $self->{tasks}->{$taskid} = {
        messages    => [],
        index       => 0,
        procname    => $procname,
        done        => 0,
        name        => $name // 'local'.$self->{_local}++,
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
    $agent->{config}->{tag} = $tag;

    my $logger = $self->event_logger();
    my $starttime = gettimeofday();
    $logger->info("Running $task->{name} task...");

    my $target;
    if ($targetid) {
        ($target) = grep { $_->id() eq $targetid } $agent->getTargets();
    }

    # If not using an agent target, create a local target and update it to run now
    unless ($target) {
        my $path = !$yaml_config->{networktask_save} || $yaml_config->{networktask_save} eq '.' ?
            "inventory" : $yaml_config->{networktask_save}."/inventory";

        # Make sure path exists as folder
        mkdir $path unless -d $path;

        GLPI::Agent::Target::Local->require();
        $target = GLPI::Agent::Target::Local->new(
            logger     => $logger,
            delaytime  => 1,
            basevardir => $agent->{vardir},
            path       => $path
        );
    }

    # Create an Inventory task
    GLPI::Agent::Task::Inventory->require();
    my $inventory = GLPI::Agent::Task::Inventory->new(
        config      => $agent->{config},
        datadir     => $agent->{datadir},
        logger      => $logger,
        target      => $target,
        deviceid    => $agent->{deviceid},
        agentid     => $agent->{agentid},
    );

    # Report modules count to prepare progress bar handling (we don't count
    # Module & Version sub modules)
    my $modules_count = scalar($inventory->getModules())-2;
    $logger->debug("Inventory modules found: $modules_count");

    $inventory->run();
    my $chrono = sprintf("%0.3f", gettimeofday() - $starttime);
    $logger->info("$task->{name}: $procname ".($inventory->{aborted} ? "aborted" : "done"));
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

    if (!defined($event) && $self->{toolbox}->{target}) {
        my $jobs = $self->yaml(jobs);
        unless (defined($jobs)) {
            return unless $self->read_yaml();
            $jobs = $self->yaml(jobs);
        }
        # Time to check if we need to run a job
        my $event = $self->{toolbox}->{target}->getEvent();
        return 0 unless $event && $event->job;
        my $name = $event->name;
        my $job  = $jobs->{$name};
        if ($job && $job->{type} && $self->isyes($job->{enabled})) {
            my $type = $job->{type};
            if ($type eq 'local') {
                my $config = $job->{config} // {};
                my $yaml = $self->yaml() || {};
                # Recycle taskid
                my ($taskid) = grep { $self->{tasks}->{$_}->{name} eq $name && $self->{tasks}->{$_}->{islocal} } keys(%{$self->{tasks}});
                $self->_run_local($config->{tag}, $yaml, $name, $taskid, $config->{target});
            } elsif ($type eq 'netscan') {
                # Recycle taskid
                my ($taskid) = grep { $self->{tasks}->{$_}->{name} eq $name && !$self->{tasks}->{$_}->{islocal} } keys(%{$self->{tasks}});
                $self->netscan($name, $taskid);
            } else {
                return 0;
            }
            my $errors = $self->errors();
            my $reset_last_run;
            if (ref($errors) eq 'ARRAY' && @{$errors}) {
                map { $self->debug($_) } @{$errors};
                $reset_last_run = $job->{last_run_date};
            }
            # Change scalar type to integer to be stored as integer in YAML
            $job->{last_run_date} = int(time);
            my $rundate = $self->_get_next_run_date($name, $job);
            $event->rundate($rundate);
            # We should reset last run on errors as we needed to set it to get next run date as usual
            $job->{last_run_date} = $reset_last_run if $reset_last_run;
            $job->{next_run_date} = $rundate;
            $self->need_save(jobs);
            $self->write_yaml();
            # Re-schedule event
            $self->{toolbox}->{target}->delEvent($event);
            $self->{toolbox}->{target}->addEvent($event);
        }
    } elsif ($event =~ /^LOGGER,([^,]*),(.*)$/) {
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

    if ($event =~ /^\[debug\] initializing block (.*)$/) {
        my $block = Net::IP->new($1);
        my $count = 0;
        do {
            $count++;
        } while (++$block);
        $task->{maxcount} = $count;
    } elsif ($event =~ /^\[debug\] #(\d+), scanning ([0-9a-f.:]+)/) {
        my $worker = int($1);
        $task->{workers}->[$worker] = 1
            if $worker <= $task->{maxcount};
    } elsif ($event =~ /^\[debug\] #(\d+), worker termination/) {
        my $worker = int($1);
        if ($task->{workers}->[$worker]) {
            $task->{count}++;
            $task->{unknown}++
                if !$task->{snmp}->[$worker] && !$task->{ping}->[$worker] && !$task->{arp}->[$worker];
        }
    } elsif ($event =~ /^\[debug\] #(\d+), - scanning .* with SNMP, .*: (.*)/) {
        $task->{snmp}->[int($1)] = $2 eq 'success';
    } elsif ($event =~ /^\[debug\] #(\d+), - scanning .* with .* ping: (.*)/) {
        $task->{ping}->[int($1)] = $2 eq 'success';
        _update_others($task);
    } elsif ($event =~ /^\[debug\] #(\d+), - scanning .* in arp table: (.*)/) {
        $task->{arp}->[int($1)] = $2 eq 'success';
        _update_others($task);
    } elsif ($event =~ /^\[info\] #(\d+), Netdiscovery result for .* saved in/) {
        my $worker = int($1);
        $task->{snmp_support}++ if $task->{workers}->[$worker] && $task->{snmp}->[$worker];
        $self->update_results();
    } elsif ($event =~ /^\[info\] #(\d+), Netinventory result for .* saved in/) {
        my $worker = int($1);
        $task->{inventory_count}++ if $task->{workers}->[$worker] && $task->{snmp}->[$worker];
        $self->update_results();
    } elsif ($event =~ /^\[warning\] job \d+ aborted/) {
        $task->{aborted} = 1;
    } elsif ($event =~ /network scan done/) {
        delete $task->{snmp};
        delete $task->{ping};
        delete $task->{arp};
        delete $task->{threads};
        delete $task->{maxthreads};
        # Guaranty to set progress bar at 100%
        $task->{count} = $task->{maxcount};
    } elsif ($event =~ /local inventory aborted/) {
        $task->{aborted} = 1;
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
    } elsif ($event =~ /\[error\] Can't write to/) {
        $task->{failed} = 1;
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
    }
    $headers{'X-Inventory-Status'} = 'aborted'
        if $task->{aborted};
    $headers{'X-Inventory-Status'} = 'failed'
        if $task->{failed};

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

    $self->store_in_session( 'jobs_ordering_column' => $form->{'col'} )
        if $form->{'col'} && $form->{'col'} =~ /^name|type|config|scheduling|last_run_date|next_run_date|description$/;

    $self->store_in_session( 'jobs_order' => $form->{'order'} )
        if $form->{'order'} && $form->{'order'} =~ /^ascend|descend$/;

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

    $self->edit($form->{'edit'}) if defined($form->{'edit'});

    foreach my $handler (keys(%handlers)) {
        if (exists($form->{$handler})) {
            $self->debug2("Handling form as $handler");
            &{$handlers{$handler}}($self, $form, $yaml);
            last;
        }
    }
}

sub _load_jobs {
    my ($self) = @_;

    my $jobs = $self->yaml(jobs) // {};
    my $target = $self->{toolbox}->{target};
    foreach my $name (keys(%{$jobs})) {
        my $job = $jobs->{$name}
            or next;
        next unless $self->isyes($job->{enabled});
        my %event = (
            job     => 1,
            name    => $name,
            task    => $job->{type} eq 'local' ? "inventory" : "netscan",
        );
        my $event = GLPI::Agent::Event->new(%event);
        if ($job->{next_run_date} && $job->{next_run_date} > time) {
            $event->rundate($job->{next_run_date});
        } else {
            my $rundate = $self->_get_next_run_date($name, $job);
            $event->rundate($rundate);
            $job->{next_run_date} = $rundate;
            $self->need_save(jobs);
        }
        $target->delEvent($event);
        $target->addEvent($event);
    }

    # Save updated jobs if required
    $self->write_yaml();
}

sub _get_next_run_date {
    my ($self, $name, $job, $not_before) = @_;

    return unless $job;

    # not_before could be reset when job is forced to run now
    $self->{_not_before} = {} unless $self->{_not_before};
    $not_before = $self->{_not_before}->{$name} // 0
        unless $not_before;

    my $last = $job->{last_run_date} // 0;
    my $scheduling = $self->yaml('scheduling') // {};

    my %wd = qw( sun 0 mon 1 tue 2 wed 3 thu 4 fri 5 sat 6 );

    my @delay;
    foreach my $schedule (@{$job->{scheduling}}) {
        my $sched = $scheduling->{$schedule}
            or next;
        next unless $sched->{type};
        my $now = time;
        if ($sched->{type} eq 'delay' && $sched->{delay}) {
            my ($delay, $unit) = $sched->{delay} =~ /^(\d+)(s|m|h|d|w)$/
                or next;
            $delay = int($delay) * ($unit eq 's' ? 1 :
                                    $unit eq 'm' ? 60 :
                                    $unit eq 'h' ? 3600 :
                                    $unit eq 'd' ? 86400 : 7*86400);
            my $next_start = $last + $delay;
            $next_start = $not_before if $next_start < $not_before;
            my $fuzzy = $delay >= 86400 ? int(rand(3600)-1800) :
                        $delay >=  3600 ? int(rand(300)-150)   :
                        $delay >=   120 ? int(rand(10)-5)      : 0 ;
            if ($next_start + $fuzzy < $now) {
                $next_start = $now;
                $fuzzy      = int(rand($delay > 60 ? 60 : $delay));
            }
            push @delay, {
                start       => $next_start + $fuzzy,
                not_before  => $next_start + $delay,
            };
        } elsif ($sched->{type} eq 'timeslot' && $sched->{start} && $sched->{duration} && $sched->{weekday}) {
            my @cur = localtime($now);
            my $daystart = $now - $cur[2]*3600 - $cur[1]*60 - $cur[0];
            my ($h, $m) = $sched->{start} =~ /^(\d{2}):(\d{2})$/
                or next;
            my ($hd, $dm) = $sched->{duration} =~ /^(\d{2}):(\d{2})$/
                or next;
            my $hmstart = int($h)*3600 + int($m)*60;
            my $duration = int($hd)*3600 + int($dm)*60;

            # Find all timeslot start time for max a 2 weeks windows around the current day, this guarantee to find at least 2 timeslots including the next one
            my @ts;
            my $rangedays = $sched->{weekday} eq '*' ? 1 : 7;
            foreach my $thisday (-$rangedays..$rangedays) {
                if ($sched->{weekday} ne '*') {
                    my $weekday = ($cur[6] + $thisday) % 7;
                    next unless $wd{$sched->{weekday}} == $weekday;
                }
                push @ts, $daystart + $thisday*86400 + $hmstart;
            }

            # From found timeslot start times, extract the next start and the previous
            my ($prevstart, $nextstart);
            while (@ts) {
                my $start = pop @ts;
                if ($start > $now) {
                    $nextstart = $start;
                } else {
                    $prevstart = $start;
                    last;
                }
            }

            # If we are in the previous windows and it has not been run, we still have to start during it
            # Or we have to start during the following windows
            if ($now >= $prevstart && $now < $prevstart+$duration && (!$last || $last < $prevstart)) {
                push @delay, {
                    start       => $now + int(rand($prevstart + $duration - $now)),
                    not_before  => $prevstart + $duration
                };
            } else {
                push @delay, {
                    start       => $nextstart + int(rand($duration)),
                    not_before  => $nextstart + $duration
                };
            }
        }
    }

    # Choose sooner delay
    my $rundate = shift @delay;
    foreach my $delay (@delay) {
        $rundate = $delay if $delay->{start} < $rundate->{start};
    }

    # Keep not before for next run date request
    $self->{_not_before}->{$name} = $rundate->{not_before};

    return $rundate->{start};
}

1;
