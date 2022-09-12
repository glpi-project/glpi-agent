package GLPI::Agent::HTTP::Server::ToolBox::IpRange;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox";

use English qw(-no_match_vars);
use Encode qw(encode);
use HTML::Entities;
use Net::IP;

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;

use constant    ip_range    => "ip_range";

sub index {
    return ip_range;
}

sub log_prefix {
    return "[toolbox plugin, ip_range] ";
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
        iprange_navbar  => {
            category    => "Navigation bar",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'iprange_navbar'}),
            text        => "Show IP Ranges in navigation bar",
            navbar      => "IP Ranges",
            link        => $self->index(),
            index       => 40, # index in navbar
        },
        iprange_yaml  => {
            category    => "IP Ranges",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "option" : "readonly",
            value       => $yaml_config->{'iprange_yaml'} || (
                $self->isyes($yaml_config->{'updating_support'}) ? "" : "[default]"),
            options     => $self->yaml_files(),
            text        => "IP Ranges YAML file",
            yaml_base   => ip_range,
        }
    };
}

sub update_template_hash {
    my ($self, $hash) = @_;

    return unless $hash;

    my $yaml = $self->yaml() || {};
    my $ip_range = $self->yaml('ip_range') || {};
    my $credentials = $self->yaml('credentials') || {};
    my $yaml_config = $self->yaml('configuration') || {};

    # Update Text::Template HASH but protect some values by encoding html entities
    foreach my $base (qw(ip_range credentials)) {
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
    $hash->{title} = "IP Ranges";

    # Don't include listing datas when editing
    return if $self->edit();

    $hash->{columns} = [
        [ name        => "IP range name" ],
        [ ip_start    => "First ip"      ],
        [ ip_end      => "Last ip"       ],
        [ credentials => "Credentials"   ],
        [ description => "Description"   ]
    ];
    $hash->{order} = $self->get_from_session('iprange_order') || "ascend";
    my $asc = $hash->{order} eq 'ascend';
    my $ordering = $hash->{ordering_column} = $self->get_from_session('iprange_ordering_column') || 'name';
    my $ip_ordering = $ordering =~ /^ip/;
    my $credentials_ordering = $ordering =~ /^credentials/;
    my $name_ordering = $ordering eq 'name';
    $hash->{ranges_order} = [
        sort {
            my ($A, $B) =  $asc ? ( $a, $b ) : ( $b, $a );
            if ($ip_ordering) {
                __compare_ip($ip_range, $ordering, $A, $B);
            } elsif ($credentials_ordering) {
                my @A = sort @{$ip_range->{$A}->{$ordering} || []};
                my @B = sort @{$ip_range->{$B}->{$ordering} || []};
                 join(',',@A) cmp join(',',@B) || $A cmp $B
            } elsif ($name_ordering) {
                $A cmp $B
            } else {
                ($ip_range->{$A}->{$ordering} || '') cmp ($ip_range->{$B}->{$ordering} || '')
                    || $A cmp $B
            }
        } keys(%{$ip_range})
    ];
    my @display_options = grep { /^\d+$/ } split(/[|]/,$yaml_config->{display_options} || '30|0|5|10|20|40|50|100|500');
    $hash->{display_options} = [ sort { $a <=> $b } keys(%{{map { $_ => 1 } @display_options}}) ];
    my $display = $self->get_from_session('display');
    $hash->{display} = length($display) ? $display : $display_options[0];
    $hash->{cred_options} = [ sort { $a cmp $b } map { encode('UTF-8', encode_entities($_)) } keys(%{$credentials}) ];
    $hash->{list_count} = scalar(keys(%{$ip_range}));
    $self->delete_in_session('iprange_start') unless $hash->{display};
    $hash->{start} = $self->get_from_session('iprange_start') || 1;
    $hash->{start} = $hash->{list_count} if $hash->{start} > $hash->{list_count};
    $hash->{page} = $hash->{display} ? int(($hash->{start}-1)/$hash->{display})+1 : 1;
    $hash->{pages} = $hash->{display} ? int(($hash->{list_count}-1)/$hash->{display})+1 : 1;
    $hash->{start} = $hash->{display} ? $hash->{start} - $hash->{start}%$hash->{display} : 0;
    # Handle case we are indexing the last element
    $hash->{start} -= $hash->{display} if $hash->{start} == $hash->{list_count};
    $hash->{start} = 0 if $hash->{start} < 0;
}

sub __compare_ip {
    my ($ip_range, $ordering, $a, $b) = @_;
    return 0 unless $ip_range && $ip_range->{$a} && $ip_range->{$b};
    # Try first to compare on first ip
    my $cmp = __sortable_ip($ip_range->{$a}->{$ordering}) cmp __sortable_ip($ip_range->{$b}->{$ordering});
    return $cmp if $cmp;
    # Then try to compare on other ip
    my $other = $ordering eq 'ip_start' ? 'ip_end' : 'ip_start';
    $cmp = __sortable_ip($ip_range->{$a}->{$other}) cmp __sortable_ip($ip_range->{$b}->{$other});
    return $cmp if $cmp;
    # Finally compare on name
    return $a cmp $b
}

sub __sortable_ip {
    my ($ip) = @_;
    return '' unless $ip;
    return $ip unless $ip =~ /^\d+\.\d+\.\d+\.\d+$/;
    # encoding ip as hex string make it sortable by cmp comparator
    return join("", map { sprintf("%02X",$_) } split(/\./, $ip));
}

sub _submit_add {
    my ($self, $form, $ip_range) = @_;

    return unless $form && $ip_range;

    $form->{allow_name_edition} = $form->{empty};

    # Validate input/name before updating
    my $name = trimWhitespace($form->{'input/name'} || $form->{'edit'} || "");
    if ($name && exists($ip_range->{$name})) {
        $name = encode('UTF-8', $name);
        return $self->errors("New IP range: An entry still exists with that name: '$name'");
    }
    if ($name) {
        # Validate form
        if (!$form->{"input/ip_start"}) {
            return $self->errors("New IP range: Start ip is mandatory");
        } elsif (!Net::IP->new($form->{"input/ip_start"})) {
            return $self->errors("New IP range: Wrong start ip format");
        } elsif (!$form->{"input/ip_end"}) {
            return $self->errors("New IP range: End ip is mandatory");
        } elsif (!Net::IP->new($form->{"input/ip_end"})) {
            return $self->errors("New IP range: Wrong end ip format");
        }
        # Validate IP Range as expected in NetDiscovery task
        my $block = Net::IP->new( $form->{"input/ip_start"}."-".$form->{"input/ip_end"} );
        return $self->errors("IP range update: Unsupported IP range: ".Net::IP->Error())
            if (!$block || $block->{binip} !~ /1/);
        # Add IP range
        $ip_range->{$name} = {};
        foreach my $key (qw(ip_start ip_end description)) {
            my $input = "input/$key";
            if (defined($form->{$input}) && length($form->{$input})) {
                $ip_range->{$name}->{$key} = $form->{$input};
            } else {
                delete $ip_range->{$name}->{$key};
            }
        }
        my @credentials = sort { $a cmp $b } map { m{^checkbox/(.*)$} }
            grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});
        if (@credentials) {
            $ip_range->{$name}->{credentials} = \@credentials;
        } else {
            delete $ip_range->{$name}->{credentials};
        }
        $self->need_save(ip_range);
        delete $form->{empty};
        delete $form->{allow_name_edition};
    } else {
        $self->errors("New IP range: Can't create entry without name") if $form->{empty};
        # We should return an empty add form with name edition allowed
        $form->{empty} = 1;
        $form->{allow_name_edition} = 1;
    }
}

sub _submit_rename {
    my ($self, $form) = @_;

    return unless $form;

    # Just enable the name field
    $form->{allow_name_edition} = 1;
}

sub _submit_update {
    my ($self, $form, $ip_range) = @_;

    return unless $form && $ip_range;

    my $update = $form->{'edit'};
    if ($update && exists($ip_range->{$update})) {
        # Validate input/name before updating
        my $name = $form->{'input/name'} || $update;
        my $id   = $form->{'input/id'};
        my $entry = $name . ( $id ? "-$id" : "" );
        if ($entry && $entry ne $update && exists($ip_range->{$entry})) {
            $name = encode('UTF-8', $name);
            return $self->errors("IP range update: An entry still exists with that name: '$name'");
        }
        # Rename the entry if necessary
        $ip_range->{$entry} = delete $ip_range->{$update}
            if ($entry ne $update);
        $self->edit($entry);
        # Validate form
        if (!$form->{"input/ip_start"}) {
            return $self->errors("IP range update: Start ip is mandatory");
        } elsif (!Net::IP->new($form->{"input/ip_start"})) {
            return $self->errors("IP range update: Wrong start ip format");
        } elsif (!$form->{"input/ip_end"}) {
            return $self->errors("IP range update: End ip is mandatory");
        } elsif (!Net::IP->new($form->{"input/ip_end"})) {
            return $self->errors("IP range update: Wrong end ip format");
        }
        # Validate IP Range as expected in NetDiscovery task
        my $block = Net::IP->new( $form->{"input/ip_start"}."-".$form->{"input/ip_end"} );
        return $self->errors("IP range update: Unsupported IP range: ".Net::IP->Error())
            if (!$block || $block->{binip} !~ /1/);
        # Update IP range
        foreach my $key (qw(ip_start ip_end description)) {
            my $input = "input/$key";
            if (defined($form->{$input}) && length($form->{$input})) {
                $ip_range->{$entry}->{$key} = $form->{$input};
            } else {
                delete $ip_range->{$entry}->{$key};
            }
        }
        my @credentials = sort { $a cmp $b } map { m{^checkbox/(.*)$} }
            grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});
        if (@credentials) {
            $ip_range->{$entry}->{credentials} = \@credentials;
        } else {
            delete $ip_range->{$entry}->{credentials};
        }
        $self->need_save(ip_range);
        $self->reset_edit();
    }
}

sub _submit_delete {
    my ($self, $form, $ip_range) = @_;

    return unless $form && $ip_range;

    my @delete = map { m{^checkbox/(.*)$} }
        grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});

    return $self->errors("Deleting IP range: No IP range selected")
        unless @delete;

    foreach my $name (@delete) {
        delete $ip_range->{$name};
        $self->need_save(ip_range);
    }
}

sub _submit_addcredential {
    my ($self, $form, $ip_range) = @_;

    my $yaml = $self->yaml() || {};
    my $credentials = $yaml->{credentials} || {};

    return unless $form && $ip_range && $credentials;

    $form->{allow_name_edition} = $form->{empty};

    my $credential = $form->{'input/credentials'};
    return $self->errors("IP range credential adding: No credential selected")
        if (defined($credential) && !length($credential));
    return $self->errors("IP range credential adding: Invalid credential")
        unless (defined($credential) && length($credential));
    return $self->errors("IP range credential adding: Not existing credential")
        unless exists($credentials->{$credential});

    if (defined($form->{'edit'})) {
        my $name = $form->{'edit'};
        $form->{empty} = 1 unless $name;
        $form->{"checkbox/$credential"} = "on";
    } else {
        my @selected = map { m{^checkbox/(.*)$} }
            grep { m{^checkbox/} && $form->{$_} eq 'on' } keys(%{$form});

        return $self->errors("IP range credential adding: No IP range selected")
            unless @selected;

        foreach my $name (@selected) {
            next unless $ip_range->{$name};
            my %creds = $ip_range->{$name}->{credentials} ?
                map { $_ => 1 } @{$ip_range->{$name}->{credentials}} : ();
            $creds{$credential}++;
            $ip_range->{$name}->{credentials} = [ sort { $a cmp $b } keys(%creds) ];
            $self->need_save(ip_range);
        }
    }
}

sub _submit_rmcredential {
    my ($self, $form, $ip_range) = @_;

    return unless $form && $ip_range;

    my $credential = $form->{'input/credentials'};
    return $self->errors("IP range credential removing: Invalid credential")
        unless (defined($credential) && length($credential));
    my @selected = map { m{^checkbox/(.*)$} }
        grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});

    return $self->errors("IP range credential removing: No IP range selected")
        unless @selected;

    foreach my $name (@selected) {
        unless ($ip_range->{$name}) {
            $name = encode('UTF-8', $name);
            $self->errors("IP range credential removing: No such IP range: $name");
            next;
        }
        unless ($ip_range->{$name}->{credentials}) {
            $self->errors("IP range credential removing: No credentials");
            next;
        }
        $ip_range->{$name}->{credentials} = [
            grep { $_ ne $credential } @{$ip_range->{$name}->{credentials}}
        ];
        $self->need_save(ip_range);
    }
}

sub _submit_cancel {
    my ($self) = @_;
    $self->reset_edit();
}

my %handlers = (
    'submit/add'            => \&_submit_add,
    'submit/rename'         => \&_submit_rename,
    'submit/update'         => \&_submit_update,
    'submit/delete'         => \&_submit_delete,
    'submit/addcredential'  => \&_submit_addcredential,
    'submit/rmcredential'   => \&_submit_rmcredential,
    'submit/cancel'         => \&_submit_cancel,
);

sub handle_form {
    my ($self, $form) = @_;

    return unless $form && $form->{form} && $form->{form} =~ /^ip_range$/;

    my $yaml = $self->yaml() || {};

    # Only handle ip_range edition if the ip_range edition is really enabled
    my $yaml_config = $yaml->{configuration} || {};
    return unless $self->isyes($yaml_config->{'iprange_navbar'});

    # Save few values in session
    $self->store_in_session( 'iprange_ordering_column' => $form->{'col'} )
        if $form->{'col'} && $form->{'col'} =~ /^name|ip_start|ip_end|credentials|description$/;

    $self->store_in_session( 'iprange_order' => $form->{'order'} )
        if $form->{'order'} && $form->{'order'} =~ /^ascend|descend$/;

    $self->store_in_session( 'iprange_start' => int($form->{'start'}) )
        if defined($form->{'start'}) && $form->{'start'} =~ /^\d+$/;

    $self->store_in_session( 'display' => $form->{'display'} =~ /^\d+$/ ? $form->{'display'} : 0 )
        if defined($form->{'display'});

    $self->edit($form->{'edit'}) if defined($form->{'edit'});

    my $ip_range = $yaml->{ip_range} || {};

    foreach my $handler (keys(%handlers)) {
        if (exists($form->{$handler})) {
            $self->debug2("Handling form as $handler");
            &{$handlers{$handler}}($self, $form, $ip_range);
            last;
        }
    }

    # Replace ip_range reference
    $self->yaml({ ip_range => $ip_range })
        if $self->save_needed(ip_range);
}

1;
