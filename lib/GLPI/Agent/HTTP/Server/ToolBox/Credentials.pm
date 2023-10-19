package GLPI::Agent::HTTP::Server::ToolBox::Credentials;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox";

use English qw(-no_match_vars);
use Encode qw(encode);
use HTML::Entities;

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;

use constant    credentials => "credentials";

sub index {
    return credentials;
}

sub log_prefix {
    return "[toolbox plugin, credentials] ";
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
        credentials_navbar  => {
            category    => "Navigation bar",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'credentials_navbar'}),
            text        => "Show Credentials in navigation bar",
            navbar      => "Credentials",
            link        => $self->index(),
            icon        => "key",
            index       => 50, # index in navbar
        },
        credentials_yaml  => {
            category    => "IP Ranges",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "option" : "readonly",
            value       => $yaml_config->{'credentials_yaml'} || (
                $self->isyes($yaml_config->{'updating_support'}) ? "" : "[default]"),
            options     => $self->yaml_files(),
            text        => "Credentials YAML file",
            yaml_base   => credentials,
        }
    };
}

sub update_template_hash {
    my ($self, $hash) = @_;

    return unless $hash;

    my $yaml = $self->yaml() || {};
    my $credentials = $self->yaml('credentials') || {};
    my $yaml_config = $self->yaml('configuration') || {};

    # Update Text::Template HASH but protect some values by encoding html entities
    foreach my $base (qw(credentials)) {
        $hash->{$base} = {};
        next unless $yaml->{$base};
        foreach my $name (keys(%{$yaml->{$base}})) {
            my $entry = $yaml->{$base}->{$name};
            foreach my $key (keys(%{$entry})) {
                my $value = $entry->{$key};
                next unless defined($value);
                $value = encode('UTF-8', encode_entities($value))
                    if $key =~ /^name|description|username|authpassword|privpassword$/;
                $hash->{$base}->{$name}->{$key} = $value;
            }
        }
    }
    $hash->{title} = "Credentials";

    # Don't include listing datas when editing
    return if $self->edit();

    $hash->{columns} = [
        [ name        => "Credentials name" ],
        [ type        => "Type"             ],
        [ config      => "Configuration"    ],
        [ description => "Description"      ]
    ];
    $hash->{order} = $self->get_from_session('credentials_order') || "ascend";
    my $asc = $hash->{order} eq 'ascend';
    my $ordering = $hash->{ordering_column} = $self->get_from_session('credentials_ordering_column') || 'name';
    my %type_order = qw( unknown 0 esx 1 snmp_v1 2 snmp_v2c 3 snmp_v3 4 ssh 5 winrm 6);
    $hash->{credentials_order} = [
        sort {
            my ($A, $B) =  $asc ? ( $a, $b ) : ( $b, $a );
            if ($ordering eq 'config') {
                ($credentials->{$A}->{community} || $credentials->{$A}->{username} || '') cmp ($credentials->{$B}->{community} || $credentials->{$B}->{username} || '')
                    || $A cmp $B
            } elsif ($ordering eq 'type') {
                my ($typeA, $typeB) = map {
                    if (!$credentials->{$_}->{type} || $credentials->{$_}->{type} eq 'snmp') {
                        $credentials->{$_}->{snmpversion} ? 'snmp_'.$credentials->{$_}->{snmpversion} : 'unknown';
                    } else {
                        $credentials->{$_}->{type};
                    }
                } ($A, $B);
                ($type_order{$typeA} || 0) <=> ($type_order{$typeB} || 0)
                    || $A cmp $B
            } else {
                ($credentials->{$A}->{$ordering} || '') cmp ($credentials->{$B}->{$ordering} || '')
                    || $A cmp $B
            }
        } keys(%{$credentials})
    ];
    my @display_options = grep { /^\d+$/ } split(/[|]/,$yaml_config->{display_options} || '30|0|5|10|20|40|50|100|500');
    $hash->{display_options} = [ sort { $a <=> $b } keys(%{{map { $_ => 1 } @display_options}}) ];
    my $display = $self->get_from_session('display');
    $hash->{display} = length($display) ? $display : $display_options[0];
    $hash->{list_count} = scalar(@{$hash->{credentials_order}});
    $self->delete_in_session('credentials_start') unless $hash->{display};
    $hash->{start} = $self->get_from_session('credentials_start') || 1;
    $hash->{start} = $hash->{list_count} if $hash->{start} > $hash->{list_count};
    $hash->{page} = $hash->{display} ? int(($hash->{start}-1)/$hash->{display})+1 : 1;
    $hash->{pages} = $hash->{display} ? int(($hash->{list_count}-1)/$hash->{display})+1 : 1;
    $hash->{start} = $hash->{display} ? $hash->{start} - $hash->{start}%$hash->{display} : 0;
    # Handle case we are indexing the last element
    $hash->{start} -= $hash->{display} if $hash->{start} == $hash->{list_count};
    $hash->{start} = 0 if $hash->{start} < 0;
}

sub _submit_add {
    my ($self, $form, $credentials) = @_;

    return unless $form && $credentials;

    # Validate input/name before updating
    my $name = $form->{'input/name'};
    if ($name && exists($credentials->{$name})) {
        $name = encode('UTF-8', $name);
        return $self->errors("New credential: An entry still exists with that name: '$name'");
    }
    if ($form->{'input/name'}) {
        my @keys;
        # Validate form
        my $type = $form->{"input/type"} // "snmp";
        if ($type eq 'snmp') {
            if (!$form->{"input/snmpversion"}) {
                return $self->errors("New credential: SNMP version is mandatory");
            } elsif ($form->{"input/snmpversion"} !~ /v1|v2c|v3/) {
                return $self->errors("New credential: Wrong SNMP version");
            } elsif ($form->{"input/snmpversion"} =~ /v1|v2c/ && !$form->{"input/community"}) {
                return $self->errors("New credential: Community is mandatory with version: ".$form->{"input/snmpversion"});
            } elsif ($form->{"input/snmpversion"} =~ /v3/ && !$form->{"input/username"}) {
                return $self->errors("New credential: Username is mandatory with SNMP v3");
            } elsif ($form->{"input/port"} && ($form->{"input/port"} !~ /^\d+$/ || int($form->{"input/port"}) < 0 || int($form->{"input/port"}) > 65535)) {
                return $self->errors("New credential: Invalid SNMP port");
            } elsif ($form->{"input/protocol"} && $form->{"input/protocol"} !~ /^udp|tcp+$/) {
                return $self->errors("New credential: Invalid SNMP protocol");
            }
            # Cleanup unused by version
            if ($form->{"input/snmpversion"} =~ /^v1|v2c$/) {
                foreach my $key (qw(username authprotocol authpassword privprotocol privpassword)) {
                    delete $form->{"input/$key"};
                }
            } else {
                delete $form->{"input/community"};
            }
            # Required to show the same list version on reload
            $form->{snmpversion} = $form->{"input/snmpversion"};
            # Supported keys
            @keys = qw(snmpversion community description username authprotocol authpassword privprotocol privpassword port protocol);
        } else {
            if ($type !~ /^ssh|winrm|esx$/) {
                return $self->errors("New credential: Unsupported remote inventory type");
            } elsif (!(defined($form->{"input/remoteuser"}) && length($form->{"input/remoteuser"}))) {
                return $self->errors("New credential: Username is mandatory for remote inventory types");
            } elsif ($type =~ /^winrm|esx$/ && !(defined($form->{"input/remotepass"}) && length($form->{"input/remotepass"}))) {
                return $self->errors(sprintf("New credential: Password is mandatory for this remote inventory type: %s", $type));
            } elsif ($type =~ /^ssh$/ && !(defined($form->{"input/remotepass"}) && length($form->{"input/remotepass"}))) {
                $self->infos("New credential: No password for ssh remote inventory type involves you installed public key authentication");
            } elsif ($type ne 'esx' && $form->{"input/port"} && ($form->{"input/port"} !~ /^\d+$/ || int($form->{"input/port"}) < 0 || int($form->{"input/port"}) > 65535)) {
                return $self->errors(sprintf("New credential: Invalid %s port", uc($type)));
            } elsif ($type eq 'esx' && $form->{"input/port"}) {
                $self->infos("New credential: Port definition ignored");
            } elsif (grep { m{^checkbox/mode/} && $form->{$_} eq 'on'} keys(%{$form})) {
                my @modes = map { m{^checkbox/mode/(.*)$} } grep { m{^checkbox/mode/} } keys(%{$form});
                foreach my $mode (@modes) {
                    return $self->errors(sprintf("New credential: Unsupported mode for SSH removeinventory: %s", $mode))
                        if $type eq 'ssh' && $mode !~ /^ssh|libssh2|perl$/;
                    return $self->errors(sprintf("New credential: Unsupported mode for WINRM removeinventory: %s", $mode))
                        if $type eq 'winrm' && $mode !~ /^ssl$/;
                }
                $form->{'input/mode'} = join(",", @modes);
            }
            # Supported keys
            @keys = qw(description type remoteuser remotepass port mode);
        }
        # Add credential
        $credentials->{$name} = {};
        foreach my $key (@keys) {
            my $input = "input/$key";
            # Remap remoteuser & remotepass keys
            if ($type ne "snmp") {
                $key = "username" if $key eq "remoteuser";
                $key = "password" if $key eq "remotepass";
            }
            if (defined($form->{$input}) && length($form->{$input})) {
                $credentials->{$name}->{$key} = $form->{$input};
            }
        }
        # Convert port as integer to be cleaner in yaml
        $credentials->{$name}->{port} = int($credentials->{$name}->{port})
            if exists($credentials->{$name}->{port});
        $self->need_save(credentials);
        delete $form->{empty};
    } elsif (!$name) {
        $self->errors("New credential: Can't create entry without name") if $form->{empty};
        # We still should return an empty add form
        $form->{empty} = 1;
    }
}

sub _submit_update {
    my ($self, $form, $credentials) = @_;

    return unless $form && $credentials;

    my $edit = $form->{'edit'};
    if ($edit && exists($credentials->{$edit})) {
        my @keys;
        # Validate form
        my $type = $form->{"input/type"} // "snmp";
        if ($type eq 'snmp') {
            if (!$form->{"input/snmpversion"}) {
                return $self->errors("Credential update: SNMP version is mandatory");
            } elsif ($form->{"input/snmpversion"} !~ /v1|v2c|v3/) {
                return $self->errors("Credential update: Wrong SNMP version");
            } elsif ($form->{"input/snmpversion"} =~ /v1|v2c/ && !$form->{"input/community"}) {
                return $self->errors("Credential update: Community is mandatory with version: ".$form->{"input/snmpversion"});
            } elsif ($form->{"input/snmpversion"} =~ /v3/ && !$form->{"input/username"}) {
                return $self->errors("Credential update: Username is mandatory with SNMP v3");
            } elsif ($form->{"input/port"} && ($form->{"input/port"} !~ /^\d+$/ || int($form->{"input/port"}) < 0 || int($form->{"input/port"}) > 65535)) {
                return $self->errors("Credential update: Invalid SNMP port");
            } elsif ($form->{"input/protocol"} && $form->{"input/protocol"} !~ /^udp|tcp+$/) {
                return $self->errors("Credential update: Invalid SNMP protocol");
            }
            # Supported keys
            @keys = qw(snmpversion community description username authprotocol authpassword privprotocol privpassword port protocol type);
        } else {
            if ($type !~ /^ssh|winrm|esx$/) {
                return $self->errors("Credential update: Unsupported remote inventory type");
            } elsif (!(defined($form->{"input/remoteuser"}) && length($form->{"input/remoteuser"}))) {
                return $self->errors("Credential update: Username is mandatory for remote inventory types");
            } elsif ($type =~ /^winrm|esx$/ && !(defined($form->{"input/remotepass"}) && length($form->{"input/remotepass"}))) {
                return $self->errors(sprintf("Credential update: Password is mandatory for this remote inventory type: %s", $type));
            } elsif ($type =~ /^ssh$/ && !(defined($form->{"input/remotepass"}) && length($form->{"input/remotepass"}))) {
                $self->infos("Credential update: No password for ssh remote inventory type involves you installed public key authentication");
            } elsif ($type ne 'esx' && $form->{"input/port"} && ($form->{"input/port"} !~ /^\d+$/ || int($form->{"input/port"}) < 0 || int($form->{"input/port"}) > 65535)) {
                return $self->errors(sprintf("Credential update: Invalid %s port", uc($type)));
            } elsif ($type eq 'esx' && $form->{"input/port"}) {
                $self->infos("Credential update: Port definition ignored");
            } elsif (grep { m{^checkbox/mode/} && $form->{$_} eq 'on'} keys(%{$form})) {
                my @modes = map { m{^checkbox/mode/(.*)$} } grep { m{^checkbox/mode/} } keys(%{$form});
                foreach my $mode (@modes) {
                    return $self->errors(sprintf("Credential update: Unsupported mode for SSH removeinventory: %s", $mode))
                        if $type eq 'ssh' && $mode !~ /^ssh|libssh2|perl$/;
                    return $self->errors(sprintf("Credential update: Unsupported mode for WINRM removeinventory: %s", $mode))
                        if $type eq 'winrm' && $mode !~ /^ssl$/;
                }
                $form->{'input/mode'} = join(",", @modes);
            }
            # Supported keys
            @keys = qw(description type remoteuser remotepass port mode);
        }
        if ($type eq 'snmp') {
            # Cleanup unused by version
            if ($form->{"input/snmpversion"} =~ /^v1|v2c$/) {
                foreach my $key (qw(username authprotocol authpassword privprotocol privpassword)) {
                    delete $form->{"input/$key"};
                }
            } else {
                delete $form->{"input/community"};
            }
        }

        # Support renaming
        my $newname = $form->{'input/name'};
        if (defined($newname) && length($newname) && $newname ne $edit) {
            if (exists($credentials->{$newname})) {
                $newname = encode('UTF-8', $newname);
                return $self->errors("Rename credentials: An entry still exists with that name: '$newname'");
            }

            $credentials->{$newname} = delete $credentials->{$edit};
            $self->need_save(credentials);

            # We also need to fix any credential ref in ip_range credentials entries
            my $ip_range = $self->yaml('ip_range') || {};
            my $count = 0;
            foreach my $range (values(%{$ip_range})) {
                next unless ref($range->{credentials}) eq 'ARRAY';
                next unless first { $_ eq $edit } @{$range->{credentials}};
                my @credentials = grep { $_ ne $edit } @{$range->{credentials}};
                push @credentials, $newname;
                $range->{credentials} = [ sort @credentials ];
                $count++;
            }
            if ($count) {
                $self->need_save('ip_range');
                $self->debug2("Fixed $count ip_range credential refs");
            }

            # Reset edited entry
            $edit = $newname;
            $self->edit($edit);
        }

        # Update credential
        foreach my $key (@keys) {
            my $input = "input/$key";
            # Remap remoteuser & remotepass keys
            if ($type ne "snmp") {
                $key = "username" if $key eq "remoteuser";
                $key = "password" if $key eq "remotepass";
            }
            if (defined($form->{$input}) && length($form->{$input})) {
                $credentials->{$edit}->{$key} = $form->{$input};
            } else {
                delete $credentials->{$edit}->{$key};
            }
        }
        # Convert port as integer to be cleaner in yaml
        $credentials->{$edit}->{port} = int($credentials->{$edit}->{port})
            if exists($credentials->{$edit}->{port});
        $self->need_save(credentials);
    } else {
        $self->errors("Credential update: No such credential: '$edit'");
        $self->reset_edit();
    }
}

sub _submit_delete {
    my ($self, $form, $credentials) = @_;

    return unless $form && $credentials;

    my @delete = map { m{^checkbox/(.*)$} }
        grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});

    return $self->errors("Delete credential: No credential selected")
        unless @delete;

    my $used = $self->_used_credentials(\@delete);
    return $self->errors("Delete credential: Can't delete used credential: ".$used)
        if $used;

    foreach my $name (@delete) {
        delete $credentials->{$name};
        $self->need_save(credentials);
    }
}

sub _used_credentials {
    my ($self, $delete) = @_;

    # We also need to check if any credential is used in any ip range
    my %used = ();
    my %delete = map { $_ => 1 } @{$delete};
    my $keys = keys(%delete);
    my $ipranges = $self->yaml('ip_range') || {};
    foreach my $range (values(%{$ipranges})) {
        my $credentials = $range->{credentials}
            or next;
        next unless ref($credentials) eq 'ARRAY';
        foreach my $credential (@{$credentials}) {
            next if exists($used{$credential});
            next unless exists($delete{$credential});
            $used{$credential} = encode('UTF-8', $credential);
            delete $delete{$credential};
            last unless --$keys;
        }
        last unless $keys;
    }

    return join(",", sort values(%used));
}

sub _submit_back_to_list {
    my ($self, $form) = @_;
    $self->reset_edit();
    delete $form->{empty};
}

my %handlers = (
    'submit/add'            => \&_submit_add,
    'submit/update'         => \&_submit_update,
    'submit/delete'         => \&_submit_delete,
    'submit/back-to-list'   => \&_submit_back_to_list,
);

sub handle_form {
    my ($self, $form) = @_;

    return unless $form && $form->{form} && $form->{form} =~ /^credentials$/;

    my $yaml = $self->yaml() || {};

    # Only handle credentials edition if the credentials edition is really enabled
    my $yaml_config = $yaml->{configuration} || {};
    return unless defined($yaml_config->{'credentials_navbar'}) &&
        $yaml_config->{'credentials_navbar'} =~ /^1|yes$/i;

    # Save few values in session
    $self->store_in_session( 'credentials_ordering_column' => $form->{'col'} )
        if $form->{'col'} && $form->{'col'} =~ /^name|type|config|description$/;

    $self->store_in_session( 'credentials_order' => $form->{'order'} )
        if $form->{'order'} && $form->{'order'} =~ /^ascend|descend$/;

    $self->store_in_session( 'credentials_start' => int($form->{'start'}) )
        if defined($form->{'start'}) && $form->{'start'} =~ /^\d+$/;

    $self->store_in_session( 'display' => $form->{'display'} =~ /^\d+$/ ? $form->{'display'} : 0 )
        if defined($form->{'display'});

    $self->edit($form->{'edit'}) if defined($form->{'edit'});

    my $credentials = $yaml->{credentials} || {};

    foreach my $handler (keys(%handlers)) {
        if (exists($form->{$handler})) {
            $self->debug2("Handling form as $handler");
            &{$handlers{$handler}}($self, $form, $credentials);
            last;
        }
    }

    # Replace credentials reference
    $self->yaml({ credentials => $credentials })
        if $self->save_needed(credentials);
}

1;
