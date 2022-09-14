package GLPI::Agent::HTTP::Server::ToolBox::Remotes;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox";

use English qw(-no_match_vars);
use Encode qw(encode);
use HTML::Entities;
use Time::HiRes qw(gettimeofday);

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;
use GLPI::Agent::Task::RemoteInventory::Remote;
use GLPI::Agent::Task::RemoteInventory::Remotes;

use constant    remotes => "remotes";

sub index {
    return remotes;
}

sub log_prefix {
    return "[toolbox plugin, remotes] ";
}

sub new {
    my ($class, %params) = @_;

    my ($name) = $class =~ /::(\w+)$/;

    my $agent = $params{toolbox}->{server}->{agent};

    my $self = {
        logger  => $params{toolbox}->{logger} ||
                    GLPI::Agent::Logger->new(),
        toolbox => $params{toolbox},
        name    => $name
    };

    # Initialize targets unless configurated with remote option
    unless ($agent->{config}->{remote}) {
        # Only define _count if we can handle remotes
        $self->{_count} = 0;
        foreach my $target ($agent->getTargets()) {
            my $id = $target->id();
            push @{$self->{targets}}, $id;
            $self->{target}->{$id} = $target;
        }
    }

    bless $self, $class;
}

sub _update_remotes {
    my ($self) = @_;

    return unless defined($self->{_count});

    my $agent = $self->{toolbox}->{server}->{agent};

    $self->{_count} = 0;
    foreach my $targetid (@{$self->{targets}}) {
        my $remotes = $self->{remotes}->{$targetid} = GLPI::Agent::Task::RemoteInventory::Remotes->new(
            config  => $agent->{config},
            storage => $self->{target}->{$targetid}->getStorage()
        );
        $self->{_count} += $remotes->count();
    }
}

sub yaml_config_specs {
    my ($self, $yaml_config) = @_;

    return {
        remotes_navbar  => {
            category    => "Navigation bar",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'remotes_navbar'}),
            text        => "Show Remotes in navigation bar",
            navbar      => "Remotes",
            link        => $self->index(),
            index       => 30, # index in navbar
        },
        remotes_show_password  => {
            category    => "Remotes",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'remotes_show_password'}),
            text        => "Show remote password",
        },
        remotes_admin  => {
            category    => "Remotes",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'remotes_admin'}),
            text        => "Allow remotes administration",
        },
        remotes_show_expiration  => {
            category    => "Remotes",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'remotes_show_expiration'}),
            text        => "Show remotes expiration time",
        },
        remotes_workers  => {
            category    => "Remotes",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "text" : "readonly",
            value       => $yaml_config->{'remotes_workers'} || '1|2|5|10|20',
            text        => "Remotes workers number options",
            tips        => "Remotes workers number options separated by pipes,\nfirst value used as default workers\n(default=1|2|5|10|20)",
        },
    };
}

sub update_template_hash {
    my ($self, $hash) = @_;

    return unless $hash;

    my $yaml_config = $self->yaml('configuration') || {};

    # Update Text::Template HASH but protect some values by encoding html entities

    $hash->{count}          = 0;
    $hash->{enabled}        = defined($self->{_count}) ? 1 : 0;
    $hash->{remotes_admin}  = $self->isyes($yaml_config->{'remotes_admin'});
    $hash->{has_expiration} = $self->isyes($yaml_config->{'remotes_show_expiration'});
    $hash->{show_password}  = $self->isyes($yaml_config->{'remotes_show_password'});
    my @workers_options = grep { /^\d+$/ } split(/[|]/, $yaml_config->{remotes_workers} || '1|2|5|10|20');
    $hash->{workers_options} = [ sort { $a <=> $b } keys(%{{map { $_ => 1 } @workers_options}}) ];
    $self->{workers_default} = $workers_options[0] || 1;
    $hash->{workers_option}  = $self->get_from_session('workers') || $self->{workers_default};
    $hash->{targets}        = [
        map { [ $_, $self->{target}->{$_}->getName() ] } @{$self->{targets}}
    ];

    if ($self->{tasks} && @{$self->{tasks}}) {
        $hash->{infos} = [ map { "Running task: $_" } @{$self->{tasks}} ]
            unless $hash->{infos}  && @{$hash->{infos}};
        $hash->{disable_start} = 1;
    }

    $self->_update_remotes();
    if ($hash->{enabled} && $self->{_count}) {
        $hash->{count} = $self->{_count};
        foreach my $targetid (@{$self->{targets}}) {
            my @remotes = sort { $a cmp $b } $self->{remotes}->{$targetid}->getlist();
            foreach my $remoteid (@remotes) {
                my $remote = $self->{remotes}->{$targetid}->get($remoteid);
                my $url = encode('UTF-8', encode_entities(
                    $self->isyes($yaml_config->{'remotes_show_password'}) || $self->edit() ? $remote->url() : $remote->safe_url()
                ));
                my $pass = $remote->pass() ? encode('UTF-8', encode_entities(
                    $self->isyes($yaml_config->{'remotes_show_password'}) || $self->edit() ? $remote->pass() : '****'
                )) : '';
                my $deviceid = encode('UTF-8', encode_entities($remote->deviceid()));
                my $id = $targetid.'/'.encode('UTF-8', encode_entities($remoteid));
                push @{$hash->{remotes_list}}, $id;
                my $modes = $remote->mode();
                my $this = $hash->{remotes}->{$id} = {
                    target      => $targetid,
                    protocol    => $remote->protocol(),
                    host        => encode('UTF-8', encode_entities($remote->host())),
                    port        => $remote->port(),
                    user        => encode('UTF-8', encode_entities($remote->user())),
                    pass        => $pass,
                    modes       => join(',', sort(keys(%{$modes}))),
                    deviceid    => $deviceid,
                    url         => $url,
                };
                if ($self->isyes($yaml_config->{'remotes_show_expiration'})) {
                    $this->{expiration} = $remote->expiration() && $remote->expiration() > time ?
                        localtime($remote->expiration()) : "";
                }
            }
        }
    }
    $hash->{title} = "Remotes";

    my @display_options = grep { /^\d+$/ } split(/[|]/,$yaml_config->{display_options} || '30|0|5|10|20|40|50|100|500');
    $hash->{display_options} = [ sort { $a <=> $b } keys(%{{map { $_ => 1 } @display_options}}) ];
    my $display = $self->get_from_session('display');
    $hash->{display} = length($display) ? $display : $display_options[0];
    $self->delete_in_session('remotes_start') unless $hash->{display};
    $hash->{start} = $self->get_from_session('remotes_start') || 1;
    $hash->{start} = $hash->{count} if $hash->{start} > $hash->{count};
    $hash->{page}  = $hash->{display} ? int(($hash->{start}-1)/$hash->{display})+1 : 1;
    $hash->{pages} = $hash->{display} ? int(($hash->{count}-1)/$hash->{display})+1 : 1;
    $hash->{start} = $hash->{display} ? $hash->{start} - $hash->{start}%$hash->{display} : 0;
    # Handle case we are indexing the last element
    $hash->{start} -= $hash->{display} if $hash->{start} == $hash->{count};
    $hash->{start} = 0 if $hash->{start} < 0;
}

sub _submit_add {
    my ($self, $form) = @_;

    return unless $form;

    # Reset to empty form without input/url
    unless ($form->{'input/url'}) {
        $form->{empty} = 1;
        return;
    }

    my $target = $form->{'input/target'};
    return $self->errors("New remote: Can't create entry without target")
        unless $target && $self->{remotes}->{$target};

    # Support hostname setup for deviceid
    if (defined($form->{'input/hostname'}) && $form->{'input/hostname'} ne "") {
        my $url = URI->new($form->{'input/url'});
        my $query = $url->query();
        unless ($query =~ /\b(?:host)?name=([\w.-]+)\b/) {
            $query .= "&" if $query;
            $query .= "hostname=".$form->{'input/hostname'};
            $url->query($query);
            $form->{'input/url'} = $url->as_string;
        }
    }

    my $remote = GLPI::Agent::Task::RemoteInventory::Remote->new(
        url     => $form->{'input/url'},
        logger  => $self->{logger}
    );

    delete $form->{empty};

    $remote->deviceid(deviceid => $form->{'input/deviceid'})
        if $form->{'input/deviceid'};

    my $deviceid = $self->{remotes}->{$target}->add($remote);
    $self->need_save($target);
    $self->edit($target.'/'.$deviceid);
}

sub _submit_update {
    my ($self, $form) = @_;

    return unless $form;

    my $update = $form->{'edit'}
        or return;

    return $self->errors("Update remote: Can't update entry without target")
        unless $form->{'input/target'} && $self->{remotes}->{$form->{'input/target'}};

    my ($target, $deviceid) = $update =~ /^([\w.-]+)\/(.*)$/;

    return $self->errors("Update remote: Can't update entry without source target")
        unless $target && $self->{remotes}->{$target};

    # Remove remote
    my $remote = $self->{remotes}->{$target}->del($deviceid)
        or return $self->errors("Update remote: No such remote for target: $target");
    $self->need_save($target);
    my $expiration = $remote->expiration();

    $remote = GLPI::Agent::Task::RemoteInventory::Remote->new(
        url     => $form->{'input/url'},
        logger  => $self->{logger}
    );

    if (defined($form->{'input/deviceid'}) && $form->{'input/deviceid'} ne "") {
        $remote->deviceid(deviceid => $form->{'input/deviceid'});
    }
    $remote->expiration($expiration) if $expiration;

    $target = $form->{'input/target'};
    $deviceid = $self->{remotes}->{$target}->add($remote);
    $self->need_save($target);
    $self->edit($target.'/'.$deviceid);
}

sub _submit_delete {
    my ($self, $form) = @_;

    return unless $form;

    my @delete = map { m{^checkbox-remotes/(.*)$} }
        grep { /^checkbox-remotes\// && $form->{$_} eq 'on' } keys(%{$form});

    foreach my $id (@delete) {
        my ($target, $deviceid) = $id =~ /^(\w+)\/(.*)$/;
        next unless $self->{remotes}->{$target};
        $self->{remotes}->{$target}->del($deviceid);
        $self->need_save($target);
    }
}

sub _submit_expire {
    my ($self, $form) = @_;

    return unless $form;

    my @expires = map { m{^checkbox-remotes/(.*)$} }
        grep { /^checkbox-remotes\// && $form->{$_} eq 'on' } keys(%{$form});

    foreach my $id (@expires) {
        my ($target, $deviceid) = $id =~ /^(\w+)\/(.*)$/;
        next unless $self->{remotes}->{$target};
        my $remote = $self->{remotes}->{$target}->get($deviceid);
        $remote->expiration(time);
        $self->need_save($target);
    }
}

sub register_events_cb {
    return 1;
}

sub events_cb {
    my ($self, $event) = @_;

    return unless defined($event);

    if ($event =~ /^REMOTEDONE,(.*)$/) {
        my $taskid = $1;
        my $current = shift @{$self->{tasks}};
        if ($current && $current eq $taskid) {
            $self->{logger}->info("$taskid: Remoteinventory task processed");
        } else {
            $self->{logger}->info("$taskid: Unexpected task processed");
        }
    } else {
        return 0;
    }

    # Return true as we handled the event
    return 1;
}

sub _submit_start {
    my ($self) = @_;

    return $self->errors("A remote inventory is still running")
        if $self->{tasks} && @{$self->{tasks}};

    my $workers = $self->get_from_session('workers') || $self->{workers_default};

    my $taskid = 'remoteinventory'.$self->{_task}++;
    push @{$self->{tasks}}, $taskid;

    # From here we can continue in a forked process
    my $agent = $self->{toolbox}->{server}->{agent};
    return if $agent->fork(
        name        => "remoteinventory",
        description => "remote inventory request",
        id          => $taskid,
    );

    my $logger = $self->{logger};
    my $starttime = gettimeofday();

    # Configure agent to use required workes and only process expired remotes
    $agent->{config}->{'remote-workers'} = $workers || 1;
    $agent->{config}->{'remote-scheduling'} = 1;

    GLPI::Agent::Task::RemoteInventory->require();

    foreach my $target (@{$self->{targets}}) {
        $logger->info("Running $taskid task for $target target...");

        # Create an RemoteInventory task
        my $remoteinventory = GLPI::Agent::Task::RemoteInventory->new(
            config       => $agent->{config},
            datadir      => $agent->{datadir},
            logger       => $logger,
            target       => $self->{target}->{$target},
            deviceid     => $agent->{deviceid},
            agentid      => $agent->{agentid},
        );

        $remoteinventory->run();
    }

    my $chrono = sprintf("%0.3f", gettimeofday() - $starttime);
    $logger->info("remoteinventory: $taskid done");
    $logger->debug("Task run in $chrono seconds");
    $agent->forked_process_event("REMOTEDONE,$taskid");
    $agent->fork_exit();
}

sub _submit_cancel {
    my ($self, $form) = @_;
    delete $form->{empty};
    $self->reset_edit();
}

my %admin_handlers = (
    'submit/add-remote'     => \&_submit_add,
    'submit/update-remote'  => \&_submit_update,
    'submit/delete-remote'  => \&_submit_delete,
    'submit/cancel'         => \&_submit_cancel,
);

my %handlers = (
    'submit/expire-remotes' => \&_submit_expire,
    'submit/start-task'     => \&_submit_start,
);

sub handle_form {
    my ($self, $form) = @_;

    return unless $form && $form->{form} && $form->{form} =~ /^remotes$/;

    $self->store_in_session( 'remotes_start' => int($form->{'start'}) )
        if defined($form->{'start'}) && $form->{'start'} =~ /^\d+$/;

    $self->store_in_session( 'display' => $form->{'display'} =~ /^\d+$/ ? $form->{'display'} : 0 )
        if defined($form->{'display'});

    $self->store_in_session( 'workers' => $form->{'workers'} =~ /^\d+$/ ? $form->{'workers'} : $self->{workers_default} || 1 )
        if defined($form->{'workers'});

    $self->_update_remotes();

    foreach my $handler (keys(%handlers)) {
        if (exists($form->{$handler})) {
            $self->debug2("Handling form as $handler");
            &{$handlers{$handler}}($self, $form);
            last;
        }
    }

    my $yaml = $self->yaml() || {};
    # Only handle remotes edition if the remote edition is really enabled
    my $yaml_config = $yaml->{configuration} || {};

    if ($form->{'edit'}) {
        if ($self->isyes($yaml_config->{'remotes_admin'})) {
            $self->edit($form->{'edit'});
        } else {
            return $self->errors("Not authorized to manage remotes");
        }
    }

    foreach my $handler (keys(%admin_handlers)) {
        if (exists($form->{$handler})) {
            if ($self->isyes($yaml_config->{'remotes_admin'})) {
                $self->debug2("Handling form as $handler");
                &{$admin_handlers{$handler}}($self, $form);
            } else {
                return $self->errors("Not authorized to manage remotes");
            }
            last;
        }
    }

    my %targets = $self->save_needed();
    foreach my $target (keys(%targets)) {
        next unless $self->{remotes}->{$target};
        $self->{remotes}->{$target}->store();
    }
}

1;
