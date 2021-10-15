package GLPI::Agent::HTTP::Server::ToolBox::MibSupport;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox";

use English qw(-no_match_vars);
use Encode qw(encode);
use HTML::Entities;

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;

use constant    mibsupport => "mibsupport";

sub index {
    return mibsupport;
}

sub log_prefix {
    return "[toolbox plugin, mibsupport] ";
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
        mibsupport_navbar  => {
            category    => "Navigation bar",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'mibsupport_navbar'}),
            text        => "Show MibSupport in navigation bar",
            navbar      => "MibSupport",
            link        => $self->index(),
            index       => 90, # index in navbar
        },
        mibsupport_disabled  => {
            category    => "MibSupport",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'mibsupport_disabled'}),
            text        => "Disable MibSupport in agent",
        },
        mibsupport_yaml  => {
            category    => "MibSupport",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "option" : "readonly",
            value       => $yaml_config->{'mibsupport_yaml'} || (
                $self->isyes($yaml_config->{'updating_support'}) ? "" : "[default]"),
            options     => $self->yaml_files(),
            text        => "MibSupport YAML file",
            yaml_base   => mibsupport,
        }
    };
}

sub update_template_hash {
    my ($self, $hash) = @_;

    return unless $hash;

    my $yaml = $self->yaml() || {};

    # Update Text::Template HASH but protect some values by encoding html entities
    foreach my $base (qw(aliases rules sysobjectid mibsupport)) {
        $hash->{$base} = {};
        next unless $yaml->{$base};
        foreach my $name (keys(%{$yaml->{$base}})) {
            my $value = $yaml->{$base}->{$name};
            next unless defined($value);
            if (ref($value) eq 'HASH') {
                $value = {};
                foreach my $key (keys(%{$yaml->{$base}->{$name}})) {
                    next unless defined($yaml->{$base}->{$name}->{$key});
                    $value->{$key} = $key =~ /^value|description$/ ?
                        encode('UTF-8', encode_entities($yaml->{$base}->{$name}->{$key}))
                        : $yaml->{$base}->{$name}->{$key};
                }
            }
            $hash->{$base}->{$name} = $value;
        }
    }

    # Update aliases
    if ($yaml->{aliases}) {
        $hash->{ordered_aliases} = [
            map {
                [ $_, $yaml->{aliases}->{$_} ]
            } sort { $a cmp $b } keys(%{$yaml->{aliases}})
        ];
    }

    # Update rules
    if ($yaml->{rules}) {
        $hash->{ordered_rules} = [ sort { $a cmp $b } keys(%{$yaml->{rules}}) ];
    }
    $hash->{type_options} = [ qw(typedef serial model manufacturer mac ip firmware firmwaredate) ];
    $hash->{valuetype_options} = [ qw(raw get-mac get-string get-serial) ];

    # Add sysobjectid ordered listing
    if ($yaml->{sysobjectid}) {
        $hash->{ordered_sysobjectid} = [ sort { $a cmp $b } keys(%{$yaml->{sysobjectid}}) ];
    }

    # Add sysorid/mibsupport ordered listing
    if ($yaml->{mibsupport}) {
        $hash->{ordered_sysorid} = [ sort { $a cmp $b } keys(%{$yaml->{mibsupport}}) ];
    }

    $hash->{title} = "MibSupport Configuration";
}

my %handlers = (
    aliases         => {
        'submit/cancel'         => \&_submit_cancel,
        'submit/add/alias'      => \&_submit_add_alias,
        'submit/update/alias'   => \&_submit_update_alias,
        'submit/delete'         => \&_submit_delete,
    },
    sysobjectid    => {
        'submit/cancel'             => \&_submit_cancel,
        'submit/add/sysobjectid'    => \&_submit_add_sysobjectid,
        'submit/update/sysobjectid' => \&_submit_update_sysobjectid,
        'submit/delete'             => \&_submit_delete,
        'submit/add/rule'           => \&_submit_add_rule_in_ruleset,
        'submit/del/rule'           => \&_submit_del_rule_in_ruleset,
    },
    sysorid         => {
        'submit/cancel'         => \&_submit_cancel,
        'submit/add/sysorid'    => \&_submit_add_sysorid,
        'submit/update/sysorid' => \&_submit_update_sysorid,
        'submit/delete'         => \&_submit_delete,
        'submit/add/rule'       => \&_submit_add_rule_in_ruleset,
        'submit/del/rule'       => \&_submit_del_rule_in_ruleset,
    },
    rules           => {
        'submit/cancel'         => \&_submit_cancel,
        'submit/add/rule'       => \&_submit_add_rule,
        'submit/update/rule'    => \&_submit_update_rule,
        'submit/delete'         => \&_submit_delete,
    },
);

sub handle_form {
    my ($self, $form) = @_;

    return unless $form && $form->{form} && $form->{form} =~ /^mibsupport$/;

    my $yaml = $self->yaml() || {};

    # Only handle mibsupport edition if the mibsupport edition is really enabled
    my $yaml_config = $yaml->{configuration} || {};
    return unless defined($yaml_config->{'mibsupport_navbar'}) &&
        $yaml_config->{'mibsupport_navbar'} =~ /^1|yes$/i;

    $self->edit($form->{'edit'}) if defined($form->{'edit'});

    if ($form->{'currenttab'}) {
        my $handlers = $handlers{$form->{'currenttab'}};
        if ($handlers) {
            foreach my $handler (keys(%{$handlers})) {
                if (exists($form->{$handler})) {
                    $self->debug2("Handling form as $handler");
                    &{$handlers->{$handler}}($self, $form, $yaml);
                    last;
                }
            }
        }
    }
}

sub _submit_cancel {
    my ($self) = @_;
    $self->reset_edit();
}

sub _submit_add_alias {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $aliases = $yaml->{aliases} || {};

    # Validate input/alias before adding
    my $alias = trimWhitespace($form->{'input/alias'} || $form->{'edit'} || "");
    if ($alias && $aliases && exists($aliases->{$alias})) {
        $alias = encode('UTF-8', $alias);
        return $self->errors("New MIBSupport alias: An entry still exists with that name: '$alias'");
    }
    if ($alias) {
        # Validate form
        my $oid = trimWhitespace($form->{'input/oid'} || "");
        if ($alias !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
            delete $form->{'input/alias'};
            return $self->errors("New MIBSupport alias: Wrong alias format");
        } elsif (!$oid) {
            return $self->errors("New MIBSupport alias: No OID provided");
        } elsif (!$self->_resolve_to_oid($oid)) {
            return $self->errors("New MIBSupport alias: Can't match to a full numeric OID");
        }
        # Add Alias
        $aliases->{$alias} = $oid;
        $yaml->{aliases} = $aliases;
        $self->need_save("aliases");
        delete $form->{empty};
    } else {
        $self->errors("New MIBSupport alias: Can't create entry without name") if $form->{empty};
        $form->{empty} = 1;
    }
}

sub _submit_update_alias {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $aliases = $yaml->{aliases} || {};

    # Validate input/alias before updating
    my $alias = trimWhitespace($form->{'input/alias'} || $form->{'edit'} || "");
    if ($alias && $alias ne $form->{'edit'} && $aliases && exists($aliases->{$alias})) {
        $alias = encode('UTF-8', $alias);
        return $self->errors("Update MIBSupport alias: An entry still exists with that name: '$alias'");
    }
    if ($alias) {
        # Validate form
        my $oid = trimWhitespace($form->{'input/oid'} || "");
        if ($alias !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
            delete $form->{'input/alias'};
            return $self->errors("Update MIBSupport alias: Wrong alias format");
        } elsif (!$oid) {
            return $self->errors("Update MIBSupport alias: No OID provided");
        } elsif (!$self->_resolve_to_oid($oid)) {
            return $self->errors("Update MIBSupport alias: Can't match to a full numeric OID");
        }
        # Support alias renaming
        if ($alias ne $form->{'edit'}) {
            delete $aliases->{$form->{'edit'}};
        }
        # Update Alias
        $aliases->{$alias} = $oid;
        $yaml->{aliases} = $aliases;
        $self->need_save("aliases");
    } else {
        $self->errors("Update MIBSupport alias: Can't update entry without alias name");
    }
    $self->reset_edit();
}

sub _normalizedOid {
    my ($self, $oid, $loop) = @_;
    my $updated = 0;
    $oid =~ s/^enterprises/.1.3.6.1.4.1/;
    $oid =~ s/^private/.1.3.6.1.4/;
    $oid =~ s/^mib-2/.1.3.6.1.2.1/;
    $oid =~ s/^iso/.1/;
    my $aliases = $self->{_yaml}->[0]->{aliases} || {};
    foreach my $alias (keys(%{$aliases})) {
        $updated++ if $oid =~ s/^$alias/$aliases->{$alias}/;
    }
    return $updated && ++$loop < 10 ? $self->_normalizedOid($oid, $loop) : $oid;
}

sub _resolve_to_oid {
    my ($self, $oid) = @_;
    return $self->_normalizedOid($oid) =~ /^(\.\d+)+/;
}

sub _submit_delete {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $tab = $form->{'currenttab'};
    if ($tab && $tab =~ /^aliases|rules|sysobjectid|sysorid$/ && $yaml->{$tab}) {
        my @delete = map { m{^checkbox/$tab/(.*)$} }
            grep { m{^checkbox/$tab/} && $form->{$_} eq 'on' } keys(%{$form});

        return $self->errors("Deleting MIBSupport entries: No entry selected")
            unless @delete;

        foreach my $name (@delete) {
            delete $yaml->{$tab}->{$name};
            $self->need_save($tab);
        }
    }
}

sub _submit_add_rule {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $rules = $yaml->{rules} || {};

    # Validate input/rule before adding
    my $rule = trimWhitespace($form->{'input/rule'} || $form->{'edit'} || "");
    if ($rule && $rules && exists($rules->{$rule})) {
        $rule = encode('UTF-8', $rule);
        return $self->errors("New MIBSupport rule: An entry still exists with that name: '$rule'");
    }
    if ($rule) {
        # Validate form
        my $value = trimWhitespace($form->{'input/value'} || "");
        if ($rule !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
            delete $form->{'input/rule'};
            $form->{empty} = 1;
            return $self->errors("New MIBSupport rule: Wrong rule name format");
        } elsif (!$form->{'input/type'}) {
            $form->{empty} = 1;
            return $self->errors("New MIBSupport rule: Rule type is missing");
        } elsif (!$value) {
            $form->{empty} = 1;
            return $self->errors("New MIBSupport rule: No value provided");
        }
        # Add Rule
        $rules->{$rule} = {
            type        => $form->{'input/type'},
            value       => $value,
            valuetype   => $form->{'input/valuetype'},
            description => $form->{'input/description'},
        };
        $yaml->{rules} = $rules;
        $self->need_save("rules");
        delete $form->{empty};
    } else {
        $self->errors("New MIBSupport rule: Can't create entry without name") if $form->{empty};
        $form->{empty} = 1;
    }
}

sub _submit_update_rule {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $rules = $yaml->{rules} || {};

    # Validate input/rule before updating
    my $rule = trimWhitespace($form->{'input/rule'} || $form->{'edit'} || "");
    if ($rule && $rule ne $form->{'edit'} && $rules && exists($rules->{$rule})) {
        $rule = encode('UTF-8', $rule);
        return $self->errors("Update MIBSupport rule: An entry still exists with that name: '$rule'");
    }
    if ($rule) {
        # Validate form
        my $value = trimWhitespace($form->{'input/value'} || "");
        if ($rule !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
            delete $form->{'input/rule'};
            $form->{empty} = 1;
            return $self->errors("Update MIBSupport rule: Wrong rule name format");
        } elsif (!$form->{'input/type'}) {
            $form->{empty} = 1;
            return $self->errors("Update MIBSupport rule: Rule type is missing");
        } elsif (!$value) {
            $form->{empty} = 1;
            return $self->errors("Update MIBSupport rule: No value provided");
        }
        # Support renaming
        if ($rule ne $form->{'edit'}) {
            delete $rules->{$form->{'edit'}};
        }
        # Update Rule
        $rules->{$rule} = {
            type        => $form->{'input/type'},
            value       => $value,
            valuetype   => $form->{'input/valuetype'},
            description => $form->{'input/description'},
        };
        $yaml->{rules} = $rules;
        $self->need_save("rules");
    } else {
        $self->errors("Update MIBSupport rule: Can't create entry without name") if $form->{empty};
    }
    $self->reset_edit();
}

sub _submit_add_sysobjectid {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $sysobjectid = $yaml->{sysobjectid} || {};

    # Validate input/name before adding
    my $name = trimWhitespace($form->{'input/name'} || $form->{'edit'} || "");
    if ($name && $sysobjectid && exists($sysobjectid->{$name})) {
        $name = encode('UTF-8', $name);
        return $self->errors("New MIBSupport sysobjectid: An entry still exists with that name: '$name'");
    }
    if ($name) {
        # Validate form
        my $oid = trimWhitespace($form->{'input/oid'} || "");
        if ($name !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
            delete $form->{'input/name'};
            $form->{empty} = 1;
            return $self->errors("New MIBSupport sysobjectid: Wrong name format");
        } elsif (!$oid) {
            $form->{empty} = 1;
            return $self->errors("New MIBSupport sysobjectid: No OID provided");
        }
        # Handle ruleset
        my @ruleset = sort { $a cmp $b } map { m{^checkbox/rules/(.*)$} }
            grep { m{^checkbox/rules/} && $form->{$_} eq 'on' } keys(%{$form});
        # Add sysobjectid match
        $sysobjectid->{$name} = {
            oid         => $oid,
            rules       => \@ruleset,
            description => $form->{'input/description'},
        };
        $yaml->{sysobjectid} = $sysobjectid;
        $self->need_save("sysobjectid");
        delete $form->{empty};
    } else {
        $self->errors("New MIBSupport sysobjectid: Can't create entry without name") if $form->{empty};
        $form->{empty} = 1;
    }
}

sub _submit_update_sysobjectid {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $sysobjectid = $yaml->{sysobjectid} || {};

    # Validate input/name before updating
    my $name = trimWhitespace($form->{'input/name'} || $form->{'edit'} || "");
    if ($name && $name ne $form->{'edit'} && $sysobjectid && exists($sysobjectid->{$name})) {
        $name = encode('UTF-8', $name);
        return $self->errors("Update MIBSupport sysobjectid: An entry still exists with that name: '$name'");
    }
    if ($name) {
        # Validate form
        my $oid = trimWhitespace($form->{'input/oid'} || "");
        if ($name !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
            delete $form->{'input/name'};
            $form->{empty} = 1;
            return $self->errors("Update MIBSupport sysobjectid: Wrong name format");
        } elsif (!$oid) {
            $form->{empty} = 1;
            return $self->errors("Update MIBSupport sysobjectid: No OID provided");
        }
        # Support renaming
        if ($name ne $form->{'edit'}) {
            delete $sysobjectid->{$form->{'edit'}};
        }
        # Handle ruleset
        my @ruleset = sort { $a cmp $b } map { m{^checkbox/rules/(.*)$} }
            grep { m{^checkbox/rules/} && $form->{$_} eq 'on' } keys(%{$form});
        # Update sysobjectid match
        $sysobjectid->{$name} = {
            oid         => $oid,
            rules       => \@ruleset,
            description => $form->{'input/description'},
        };
        $yaml->{sysobjectid} = $sysobjectid;
        $self->need_save("sysobjectid");
    } else {
        $self->errors("Update MIBSupport sysobjectid: Can't create entry without name") if $form->{empty};
    }
    $self->reset_edit();
}

sub _submit_add_sysorid {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $mibsupport = $yaml->{mibsupport} || {};

    # Validate input/name before adding
    my $name = trimWhitespace($form->{'input/name'} || $form->{'edit'} || "");
    if ($name && $mibsupport && exists($mibsupport->{$name})) {
        $name = encode('UTF-8', $name);
        return $self->errors("New MIBSupport match: An entry still exists with that name: '$name'");
    }
    if ($name) {
        # Validate form
        my $oid = trimWhitespace($form->{'input/oid'} || "");
        if ($name !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
            delete $form->{'input/name'};
            $form->{empty} = 1;
            return $self->errors("New MIBSupport match: Wrong name format");
        } elsif (!$oid) {
            $form->{empty} = 1;
            return $self->errors("New MIBSupport match: No OID provided");
        }
        # Handle ruleset
        my @ruleset = sort { $a cmp $b } map { m{^checkbox/rules/(.*)$} }
            grep { m{^checkbox/rules/} && $form->{$_} eq 'on' } keys(%{$form});
        # Add mibsupport match
        $mibsupport->{$name} = {
            oid         => $oid,
            rules       => \@ruleset,
            description => $form->{'input/description'},
        };
        $yaml->{mibsupport} = $mibsupport;
        $self->need_save("mibsupport");
        delete $form->{empty};
    } else {
        $self->errors("New MIBSupport match: Can't create entry without name") if $form->{empty};
        $form->{empty} = 1;
    }
}

sub _submit_update_sysorid {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $mibsupport = $yaml->{mibsupport} || {};

    # Validate input/name before updating
    my $name = trimWhitespace($form->{'input/name'} || $form->{'edit'} || "");
    if ($name && $name ne $form->{'edit'} && $mibsupport && exists($mibsupport->{$name})) {
        $name = encode('UTF-8', $name);
        return $self->errors("Update MIBSupport match: An entry still exists with that name: '$name'");
    }
    if ($name) {
        # Validate form
        my $oid = trimWhitespace($form->{'input/oid'} || "");
        if ($name !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
            delete $form->{'input/name'};
            $form->{empty} = 1;
            return $self->errors("Update MIBSupport match: Wrong name format");
        } elsif (!$oid) {
            $form->{empty} = 1;
            return $self->errors("Update MIBSupport match: No OID provided");
        }
        # Support renaming
        if ($name ne $form->{'edit'}) {
            delete $mibsupport->{$form->{'edit'}};
        }
        # Handle ruleset
        my @ruleset = sort { $a cmp $b } map { m{^checkbox/rules/(.*)$} }
            grep { m{^checkbox/rules/} && $form->{$_} eq 'on' } keys(%{$form});
        # Update mibsupport match
        $mibsupport->{$name} = {
            oid         => $oid,
            rules       => \@ruleset,
            description => $form->{'input/description'},
        };
        $yaml->{mibsupport} = $mibsupport;
        $self->need_save("mibsupport");
    } else {
        $self->errors("Update MIBSupport match: Can't create entry without name") if $form->{empty};
    }
    $self->reset_edit();
}

my %section = qw(sysobjectid sysobjectid sysorid mibsupport);

sub _submit_add_rule_in_ruleset {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $tab = $form->{'currenttab'}
        or return;
    my $section = $yaml->{$section{$tab}}
        or return;

    my $rule = $form->{'input/rule'};
    return $self->errors("Update ruleset: No rule selected")
        unless (defined($rule) && length($rule));
    return $self->errors("Update ruleset: Not existing rule")
        unless exists($yaml->{rules}->{$rule});

    if (defined($form->{'edit'})) {
        my $name = $form->{'edit'};
        $form->{empty} = 1 unless $name;
        $form->{"checkbox/rules/$rule"} = "on";
    } else {
        my @selected = map { m{^checkbox/$tab/(.*)$} }
            grep { m{^checkbox/$tab/} && $form->{$_} eq 'on' } keys(%{$form});

        return $self->errors("Update ruleset: No entry selected")
            unless @selected;

        foreach my $name (@selected) {
            next unless $section->{$name};
            my %ruleset = $section->{$name}->{rules} ?
                map { $_ => 1 } @{$section->{$name}->{rules}} : ();
            $ruleset{$rule}++;
            $section->{$name}->{rules} = [ sort { $a cmp $b } keys(%ruleset) ];
            $self->need_save($section{$tab});
        }
    }
}

sub _submit_del_rule_in_ruleset {
    my ($self, $form, $yaml) = @_;

    return unless $form && $yaml;

    my $tab = $form->{'currenttab'}
        or return;
    my $section = $yaml->{$section{$tab}}
        or return;

    my $rule = $form->{'input/rule'};
    return $self->errors("Remove ruleset: No rule selected")
        unless (defined($rule) && length($rule));
    my @selected = map { m{^checkbox/$tab/(.*)$} }
        grep { m{^checkbox/$tab/} && $form->{$_} eq 'on' } keys(%{$form});

    return $self->errors("Remove ruleset: No entry selected")
        unless @selected;

    $tab = "mibsupport" if $tab eq "sysorid";
    foreach my $name (@selected) {
        my $ruleset = $section->{$name}
            or next;
        next unless $ruleset->{rules};
        $ruleset->{rules} = [
            grep { $_ ne $rule } @{$ruleset->{rules}}
        ];
        $self->need_save($section{$tab});
    }
}

1;
