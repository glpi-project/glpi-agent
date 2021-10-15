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
}

sub _submit_add {
    my ($self, $form, $credentials) = @_;

    return unless $form && $credentials;

    $form->{allow_name_edition} = $form->{empty};

    # Validate input/name before updating
    my $name = $form->{'input/name'};
    if ($name && exists($credentials->{$name})) {
        $name = encode('UTF-8', $name);
        return $self->errors("New credential: An entry still exists with that name: '$name'");
    }
    if ($form->{'input/name'}) {
        # Validate form
        if (!$form->{"input/snmpversion"}) {
            return $self->errors("New credential: SNMP version is mandatory");
        } elsif ($form->{"input/snmpversion"} !~ /v1|v2c|v3/) {
            return $self->errors("New credential: Wrong SNMP version");
        } elsif ($form->{"input/snmpversion"} =~ /v1|v2c/ && !$form->{"input/community"}) {
            return $self->errors("New credential: Community is mandatory with version: ".$form->{"input/snmpversion"});
        } elsif ($form->{"input/snmpversion"} =~ /v3/ && !$form->{"input/username"}) {
            return $self->errors("Credential update: Username is mandatory with SNMP v3");
        }
        # Cleanup unused by version
        if ($form->{"input/snmpversion"} =~ /v1|v2c/) {
            foreach my $key (qw(username authprotocol authpassword privprotocol privpassword)) {
                delete $form->{"input/$key"};
            }
        } else {
            delete $form->{"input/community"};
        }
        # Add credential
        $credentials->{$name} = {};
        foreach my $key (qw(snmpversion community description username authprotocol authpassword privprotocol privpassword)) {
            my $input = "input/$key";
            if (defined($form->{$input}) && length($form->{$input})) {
                $credentials->{$name}->{$key} = $form->{$input};
            }
        }
        $self->need_save(credentials);
        delete $form->{empty};
        delete $form->{allow_name_edition};
    } elsif (!$name) {
        $self->errors("New credential: Can't create entry without name");
    }
}

sub _submit_add_v1_v2c {
    my ($self, $form) = @_;

    return unless $form;

    # We should return an empty add form with name edition allowed
    $form->{empty} = 1;
    $form->{allow_name_edition} = 1;
    $form->{snmpversion} = "v2c";
}

sub _submit_add_v3 {
    my ($self, $form) = @_;

    return unless $form;

    # We should return an empty add form with name edition allowed
    $form->{empty} = 1;
    $form->{allow_name_edition} = 1;
    $form->{snmpversion} = "v3";
}

sub _submit_rename {
    my ($self, $form) = @_;

    return unless $form;

    # Just enable the name field
    $form->{allow_name_edition} = 1;
}

sub _submit_update {
    my ($self, $form, $credentials) = @_;

    return unless $form && $credentials;

    my $update = $form->{'edit'};
    if ($update && exists($credentials->{$update})) {
        my $name = $form->{'input/name'} || $update;
        my $id   = $form->{'input/id'};
        my $entry = $name . ( $id ? "-$id" : "" );
        if ($entry && $entry ne $update && exists($credentials->{$entry})) {
            $name = encode('UTF-8', $name);
            return $self->errors("Credential update: An entry still exists with that name: '$name'");
        }
        # Validate form
        if (!$form->{"input/snmpversion"}) {
            return $self->errors("Credential update: SNMP version is mandatory");
        } elsif ($form->{"input/snmpversion"} !~ /v1|v2c|v3/) {
            return $self->errors("Credential update: Wrong SNMP version");
        } elsif ($form->{"input/snmpversion"} =~ /v1|v2c/ && !$form->{"input/community"}) {
            return $self->errors("Credential update: Community is mandatory with version: ".$form->{"input/snmpversion"});
        } elsif ($form->{"input/snmpversion"} =~ /v3/ && !$form->{"input/username"}) {
            return $self->errors("Credential update: Username is mandatory with SNMP v3");
        }
        # Rename the entry
        if ($entry ne $update) {
            $credentials->{$entry} = delete $credentials->{$update};
            # We also need to fix any credential ref in ip_range credentials entries
            my $yaml = $self->yaml() || {};
            my $ip_range = $yaml->{ip_range} || {};
            my $count = 0;
            foreach my $range (values(%{$ip_range})) {
                my $credentials = $range->{credentials}
                    or next;
                next unless @{$credentials};
                my @credentials = ();
                my $seen = 0;
                foreach my $cred (@{$credentials}) {
                    if ($cred eq $update) {
                        push @credentials, $entry;
                        $self->need_save("ip_range");
                        $seen++;
                        $count++;
                    } else {
                        push @credentials, $cred;
                    }
                }
                $range->{credentials} = \@credentials
                    if $seen;
            }
            $self->debug2("Fixed $count ip_range credential refs")
                if $count;
        }
        $self->edit($entry);
        # Cleanup unused by version
        if ($form->{"input/snmpversion"} =~ /v1|v2c/) {
            foreach my $key (qw(username authprotocol authpassword privprotocol privpassword)) {
                delete $form->{"input/$key"};
            }
        } else {
            delete $form->{"input/community"};
        }
        # Update credential
        foreach my $key (qw(name snmpversion community description username authprotocol authpassword privprotocol privpassword)) {
            my $input = "input/$key";
            if (defined($form->{$input}) && length($form->{$input})) {
                $credentials->{$entry}->{$key} = $form->{$input};
            } else {
                delete $credentials->{$entry}->{$key};
            }
        }
        $self->need_save(credentials);
    }
}

sub _submit_delete_v1_v2c {
    my ($self, $form, $credentials) = @_;

    return unless $form && $credentials;

    my @delete = map { m{^checkbox-v1-v2c/(.*)$} }
        grep { /^checkbox-v1-v2c\// && $form->{$_} eq 'on' } keys(%{$form});
    foreach my $name (@delete) {
        delete $credentials->{$name};
        $self->need_save(credentials);
    }
}

sub _submit_delete_v3 {
    my ($self, $form, $credentials) = @_;

    return unless $form && $credentials;

    my @delete = map { m{^checkbox-v3/(.*)$} }
        grep { /^checkbox-v3\// && $form->{$_} eq 'on' } keys(%{$form});
    foreach my $name (@delete) {
        delete $credentials->{$name};
        $self->need_save(credentials);
    }
}

sub _submit_cancel {
    my ($self) = @_;
    $self->reset_edit();
}

my %handlers = (
    'submit/add'            => \&_submit_add,
    'submit/add-v1-v2c'     => \&_submit_add_v1_v2c,
    'submit/add-v3'         => \&_submit_add_v3,
    'submit/rename'         => \&_submit_rename,
    'submit/update'         => \&_submit_update,
    'submit/delete-v1-v2c'  => \&_submit_delete_v1_v2c,
    'submit/delete-v3'      => \&_submit_delete_v3,
    'submit/cancel'         => \&_submit_cancel,
);

sub handle_form {
    my ($self, $form) = @_;

    return unless $form && $form->{form} && $form->{form} =~ /^credentials$/;

    my $yaml = $self->yaml() || {};

    # Only handle credentials edition if the credentials edition is really enabled
    my $yaml_config = $yaml->{configuration} || {};
    return unless defined($yaml_config->{'credentials_navbar'}) &&
        $yaml_config->{'credentials_navbar'} =~ /^1|yes$/i;

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
