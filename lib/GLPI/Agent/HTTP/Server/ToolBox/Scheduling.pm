package GLPI::Agent::HTTP::Server::ToolBox::Scheduling;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox";

use English qw(-no_match_vars);
use Encode qw(encode);
use HTML::Entities;

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;

use constant    scheduling  => "scheduling";

sub index {
    return scheduling;
}

sub log_prefix {
    return "[toolbox plugin, scheduling] ";
}

sub new {
    my ($class, %params) = @_;

    my ($name) = $class =~ /::(\w+)$/;

    my $self = {
        logger  => $params{toolbox}->{logger} ||
                    GLPI::Agent::Logger->new(),
        toolbox => $params{toolbox},
        name    => $name,
    };

    bless $self, $class;

    return $self;
}

sub yaml_config_specs {
    my ($self, $yaml_config) = @_;

    return {
        scheduling_navbar  => {
            category    => "Navigation bar",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'scheduling_navbar'}),
            text        => "Show Scheduling in navigation bar",
            navbar      => "Scheduling",
            link        => $self->index(),
            icon        => "clock-edit",
            index       => 60, # index in navbar
        },
        iprange_yaml  => {
            category    => "Scheduling",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "option" : "readonly",
            value       => $yaml_config->{'scheduling_yaml'} || (
                $self->isyes($yaml_config->{'updating_support'}) ? "" : "[default]"),
            options     => $self->yaml_files(),
            text        => "Scheduling YAML file",
            yaml_base   => scheduling,
        }
    };
}

sub update_template_hash {
    my ($self, $hash) = @_;

    return unless $hash;

    my $yaml = $self->yaml() || {};
    my $scheduling = $self->yaml(scheduling) || {};
    my $yaml_config = $self->yaml('configuration') || {};

    # Update Text::Template HASH but protect some values by encoding html entities
    foreach my $base (qw(scheduling)) {
        $hash->{$base} = {};
        next unless $yaml->{$base};
        foreach my $name (keys(%{$yaml->{$base}})) {
            my $entry = $yaml->{$base}->{$name};
            foreach my $key (keys(%{$entry})) {
                my $value = $entry->{$key};
                next unless defined($value);
                $value = encode('UTF-8', encode_entities($value))
                    if $key =~ /^name|description$/;
                $hash->{$base}->{$name}->{$key} = $value;
            }
        }
    }
    $hash->{title} = "Scheduling";

    # Don't include listing datas when editing
    return if $self->edit();

    $hash->{columns} = [
        [ name          => "Scheduling name" ],
        [ type          => "Type"            ],
        [ configuration => "Configuration"   ],
        [ description   => "Description"     ]
    ];
    $hash->{order} = $self->get_from_session('scheduling_order') || "ascend";
    my $asc = $hash->{order} eq 'ascend';
    my $ordering = $hash->{ordering_column} = $self->get_from_session('scheduling_ordering_column') || 'name';
    $hash->{scheduling_order} = [
        sort {
            my ($A, $B) =  $asc ? ( $a, $b ) : ( $b, $a );
            if ($ordering eq 'name' || $ordering eq 'configuration') {
                $A cmp $B
            } else {
                (($scheduling->{$A}->{$ordering} || "") cmp ($scheduling->{$B}->{$ordering} || "")) || $A cmp $B
            }
        } keys(%{$scheduling})
    ];
    my @display_options = grep { /^\d+$/ } split(/[|]/,$yaml_config->{display_options} || '30|0|5|10|20|40|50|100|500');
    $hash->{display_options} = [ sort { $a <=> $b } keys(%{{map { $_ => 1 } @display_options}}) ];
    my $display = $self->get_from_session('display');
    $hash->{display} = length($display) ? $display : $display_options[0];
    $hash->{list_count} = scalar(keys(%{$scheduling}));
    $self->delete_in_session('scheduling_start') unless $hash->{display};
    $hash->{start} = $self->get_from_session('scheduling_start') || 1;
    $hash->{start} = $hash->{list_count} if $hash->{start} > $hash->{list_count};
    $hash->{page}  = $hash->{display} ? int(($hash->{start}-1)/$hash->{display})+1 : 1;
    $hash->{pages} = $hash->{display} ? int(($hash->{list_count}-1)/$hash->{display})+1 : 1;
    $hash->{start} = $hash->{display} ? $hash->{start} - $hash->{start}%$hash->{display} : 0;
    # Handle case we are indexing the last element
    $hash->{start} -= $hash->{display} if $hash->{start} == $hash->{list_count};
    $hash->{start} = 0 if $hash->{start} < 0;
}

sub _submit_add {
    my ($self, $form, $scheduling) = @_;

    return unless $form && $scheduling;

    # Validate input/name before updating
    my $name = trimWhitespace($form->{'input/name'} || $form->{'edit'} || "");
    if ($name && exists($scheduling->{$name})) {
        $name = encode('UTF-8', $name);
        return $self->errors("New scheduling: An entry still exists with that name: '$name'");
    }
    if ($name) {
        # Validate form
        if (!$form->{"input/type"}) {
            return $self->errors("New scheduling: Scheduling type is mandatory");
        }
        my $config = {};
        if ($form->{"input/type"} eq "delay") {
            my $delay = $form->{"input/delay"} || 24;
            return $self->errors("New scheduling: Unsupported delay time")
                unless $delay =~ /^\d+$/;
            my $unit = $form->{"input/timeunit"} || "hour";
            return $self->errors("New scheduling: Unsupported delay time unit")
                unless $unit =~ /^second|minute|hour|day|week$/;
            return $self->errors("New scheduling: Minimum delay time is one minute")
                if $unit eq 'second' && $delay < 60;
            $config->{delay} = $delay . substr($unit, 0, 1);
        } elsif ($form->{"input/type"} eq "timeslot") {
            my $weekday = $form->{"input/weekday"} || '*';
            return $self->errors("New scheduling: Unsupported week day")
                unless $weekday =~ /^\*|mon|tue|wed|thu|fri|sat|sun$/;
            $config->{weekday} = $weekday;
            my $start = $form->{"input/start"} || '00:00';
            return $self->errors("New scheduling: Invalid timeslot")
                unless $start =~ /^(\d{2}):(\d{2})$/;
            return $self->errors("New scheduling: Invalid timeslot")
                unless $1 >= 0 && $1 < 24  && $2 >= 0 && $2 < 60;
            $config->{start} = $start;
            my $duration_time = $form->{"input/duration/value"} || "1";
            my $duration_unit = $form->{"input/duration/unit"} || "hour";
            return $self->errors("New scheduling: Invalid timeslot duration")
                unless $duration_time =~ /^\d+$/ && $duration_unit =~ /^minute|hour$/;
            my $hour = $duration_unit eq 'hour' ? int($duration_time) : int($duration_time/60);
            my $min  = $duration_unit eq 'hour' ? 0 : int($duration_time%60);
            my $duration = $hour*60 + $min;
            return $self->errors("New scheduling: Invalid timeslot duration")
                unless $duration > 0 && $duration <= 24*60;
            $config->{duration} = sprintf("%02d:%02d", $hour, $min);
        } else {
            return $self->errors("New scheduling: Unsupported scheduling type");
        }
        $scheduling->{$name} = $config;
        foreach my $key (qw(type description)) {
            my $input = "input/$key";
            if (defined($form->{$input}) && length($form->{$input})) {
                $scheduling->{$name}->{$key} = $form->{$input};
            } else {
                delete $scheduling->{$name}->{$key};
            }
        }
        $self->need_save(scheduling);
        delete $form->{empty};
    } else {
        $self->errors("New scheduling: Can't create entry without name") if $form->{empty};
        # We still should return an empty add form
        $form->{empty} = 1;
    }
}

sub _submit_update {
    my ($self, $form, $scheduling) = @_;

    return unless $form && $scheduling;

    my $edit = $form->{'edit'};
    if ($edit && exists($scheduling->{$edit})) {
        # Validate form
        my $config = $scheduling->{$edit};
        if ($config->{type} eq "delay") {
            my $delay = $form->{"input/delay"} || 24;
            return $self->errors("Scheduling update: Unsupported delay time")
                unless $delay =~ /^\d+$/;
            my $unit = $form->{"input/timeunit"} || "hour";
            return $self->errors("Scheduling update: Unsupported delay time unit")
                unless $unit =~ /^second|minute|hour|day|week$/;
            return $self->errors("Scheduling update: Minimum delay time is one minute")
                if $unit eq 'second' && $delay < 60;
            $config->{delay} = $delay . substr($unit, 0, 1);
        } elsif ($config->{type} eq "timeslot") {
            my $weekday = $form->{"input/weekday"} || '*';
            return $self->errors("Scheduling update: Unsupported week day")
                unless $weekday =~ /^\*|mon|tue|wed|thu|fri|sat|sun$/;
            $config->{weekday} = $weekday;
            my $start = $form->{"input/start"} || '00:00';
            return $self->errors("Scheduling update: Invalid timeslot")
                unless $start =~ /^(\d{2}):(\d{2})$/;
            return $self->errors("Scheduling update: Invalid timeslot")
                unless $1 >= 0 && $1 < 24  && $2 >= 0 && $2 < 60;
            $config->{start} = $start;
            my $duration_time = $form->{"input/duration/value"} || "1";
            my $duration_unit = $form->{"input/duration/unit"} || "hour";
            return $self->errors("Scheduling update: Invalid timeslot duration")
                unless $duration_time =~ /^\d+$/ && $duration_unit =~ /^minute|hour$/;
            my $hour = $duration_unit eq 'hour' ? int($duration_time) : int($duration_time/60);
            my $min  = $duration_unit eq 'hour' ? 0 : int($duration_time%60);
            my $duration = $hour*60 + $min;
            return $self->errors("Scheduling update: Invalid timeslot duration")
                unless $duration > 0 && $duration <= 24*60;
            $config->{duration} = sprintf("%02d:%02d", $hour, $min);
        } else {
            return $self->errors("Scheduling update: Unsupported scheduling type");
        }

        my $newname = $form->{'input/name'};
        if (defined($newname) && length($newname) && $newname ne $edit) {
            if (exists($scheduling->{$newname})) {
                $newname = encode('UTF-8', $newname);
                return $self->errors("Rename scheduling: An entry still exists with that name: '$newname'");
            }

            $scheduling->{$newname} = delete $scheduling->{$edit};
            $self->need_save(scheduling);

            # We also need to update any usage in tasks
            my $jobs = $self->yaml('jobs') || {};
            my $count = 0;
            foreach my $job (values(%{$jobs})) {
                my $scheduling = $job->{scheduling}
                    or next;
                next unless ref($scheduling) eq 'ARRAY' && first { $_ eq $edit } @{$scheduling};
                my @scheduling = grep { $_ ne $edit } @{$scheduling};
                push @scheduling, $newname;
                $job->{scheduling} = [ sort @scheduling ];
                $count++;
            }
            if ($count) {
                $self->need_save('jobs');
                $self->debug2("Fixed $count jobs scheduling refs");
            }

            # Reset edited entry
            $edit = $newname;
            $self->edit($edit);
        }

        # Update scheduling
        foreach my $key (qw(description)) {
            my $input = "input/$key";
            if (defined($form->{$input}) && length($form->{$input})) {
                $scheduling->{$edit}->{$key} = $form->{$input};
            } else {
                delete $scheduling->{$edit}->{$key};
            }
        }
        $self->need_save(scheduling);
    } else {
        $self->errors("Scheduling update: No such scheduling: '$edit'");
        $self->reset_edit();
    }
}

sub _submit_delete {
    my ($self, $form, $scheduling) = @_;

    return unless $form && $scheduling;

    my @delete = map { m{^checkbox/(.*)$} }
        grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});

    return $self->errors("Delete scheduling: No scheduling selected")
        unless @delete;

    # We also need to check if any scheduling is used in tasks
    my %used = ();
    my %delete = map { $_ => 1 } @delete;
    my $keys = keys(%delete);
    my $jobs = $self->yaml('jobs') || {};
    foreach my $job (values(%{$jobs})) {
        next unless ref($job->{scheduling}) eq 'ARRAY';
        foreach my $scheduling (@{$job->{scheduling}}) {
            next if exists($used{$scheduling});
            next unless exists($delete{$scheduling});
            $used{$scheduling} = encode('UTF-8', $scheduling);
            delete $delete{$scheduling};
            last unless --$keys;
        }
        last unless $keys;
    }
    return $self->errors("Delete scheduling: Can't delete used scheduling: ".join(",", sort values(%used)))
        if keys(%used);

    foreach my $name (@delete) {
        delete $scheduling->{$name};
        $self->need_save(scheduling);
    }
}

sub _submit_cancel {
    my ($self, $form) = @_;
    $self->reset_edit();
    delete $form->{empty};
}

my %handlers = (
    'submit/add'            => \&_submit_add,
    'submit/update'         => \&_submit_update,
    'submit/delete'         => \&_submit_delete,
    'submit/cancel'         => \&_submit_cancel,
);

sub handle_form {
    my ($self, $form) = @_;

    return unless $form && $form->{form} && $form->{form} =~ /^scheduling$/;

    my $yaml = $self->yaml() || {};

    # Only handle scheduling edition if the scheduling edition is really enabled
    my $yaml_config = $yaml->{configuration} || {};
    return unless $self->isyes($yaml_config->{'scheduling_navbar'});

    # Save few values in session
    $self->store_in_session( 'scheduling_ordering_column' => $form->{'col'} )
        if $form->{'col'} && $form->{'col'} =~ /^name|type|configuration|description$/;

    $self->store_in_session( 'scheduling_order' => $form->{'order'} )
        if $form->{'order'} && $form->{'order'} =~ /^ascend|descend$/;

    $self->store_in_session( 'scheduling_start' => int($form->{'start'}) )
        if defined($form->{'start'}) && $form->{'start'} =~ /^\d+$/;

    $self->store_in_session( 'display' => $form->{'display'} =~ /^\d+$/ ? $form->{'display'} : 0 )
        if defined($form->{'display'});

    $self->edit($form->{'edit'}) if defined($form->{'edit'});

    my $scheduling = $yaml->{scheduling} || {};

    foreach my $handler (keys(%handlers)) {
        if (exists($form->{$handler})) {
            $self->debug2("Handling form as $handler");
            &{$handlers{$handler}}($self, $form, $scheduling);
            last;
        }
    }

    # Replace scheduling reference
    $self->yaml({ scheduling => $scheduling })
        if $self->save_needed(scheduling);
}

1;
