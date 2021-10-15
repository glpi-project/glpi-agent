package GLPI::Agent::HTTP::Server::ToolBox::Results::CustomFields;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox::Results::Fields";

use Encode qw(encode);
use HTML::Entities;

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless $self, $class;

    return unless ($self->{results}->yaml() || $self->{results}->read_yaml());

    # Initialize custom fields
    my $custom_fields = $self->{results}->yaml('container')
        or return;
    $self->_prepare_custom_fields($custom_fields);

    $self->{_section_index} = 0;

    return $self;
}

sub any { 1 }

sub order { 10 }

sub sections {
    my ($self) = @_;

    return unless $self->{_sections} && @{$self->{_sections}};

    return @{$self->{_sections}};
}

sub fields {
    my ($self) = @_;

    return unless $self->{_fields} && @{$self->{_fields}};

    return @{$self->{_fields}};
}

sub analyze {
    my ($self, $name, $tree) = @_;

    return unless $name && $tree;

    my $query = $tree && $tree->{REQUEST} && $tree->{REQUEST}->{QUERY}
        or return;

    my @sections = ();

    my $type;
    if ($query eq 'INVENTORY') {
        $type = 'COMPUTER';
    } else {
        my $dev = $tree->{REQUEST}->{CONTENT} && $tree->{REQUEST}->{CONTENT}->{DEVICE}
            or return;
        if ($query eq 'SNMPQUERY') {
            $type = $dev->{INFO} && $dev->{INFO}->{TYPE} || 'NETWORKING';
        } elsif ($query eq 'NETDISCOVERY') {
            $type = $dev->{TYPE} || 'NETWORKING';
        }
    }
    return unless $type;

    # Filter out section by related type
    foreach my $section ($self->sections()) {
        if ($section->{match}) {
            if ($section->{match}) {
                my $re_match = qr/^$section->{match}$/;
                next if ($type !~ $re_match);
            }
        }
        push @sections, $section;
    }
    return unless @sections;

    my $custom = $type eq 'COMPUTER' ? $tree->{REQUEST}->{CONTENT}->{CUSTOM}
        : $tree->{REQUEST}->{CONTENT}->{DEVICE}->{CUSTOM} ;
    my $containers = [];
    if ($custom) {
        if (ref($custom->{CONTAINER}) eq 'ARRAY') {
            $containers = $custom->{CONTAINER};
        } else {
            $containers = [ $custom->{CONTAINER} ];
        }
    }

    my $device;
    my $edition = 0;

    foreach my $section (@sections) {
        my $prefix = $section->{prefix} || '';
        foreach my $field ($self->fields()) {
            next unless $field->{section} eq $section->{name};
            my ($container) = grep { $_->{ID} eq $section->{id} && $_->{FIELDS} } @{$containers};
            $device->{_noedit}->{$prefix.$field->{name}} = 0;
            my $value = $container && defined($container->{FIELDS}->{$field->{from}}) ?
                $container->{FIELDS}->{$field->{from}} : $field->{default_value};
            next unless defined($value);
            $device->{$prefix.$field->{name}} = $value;
            $edition++;
        }
    }

    $device->{source} = "Edition" if $edition;

    return $device;
}

sub update_xml {
    my ($self, $xml, $device) = @_;

    my $custom_parent;
    if ($device->isLocalInventory) {
        $custom_parent = $xml->{REQUEST}->{CONTENT};
    } else {
        $custom_parent = $xml->{REQUEST}->{CONTENT}->{DEVICE};
    }

    # Cleanup supported container fields
    my $custom = $custom_parent && ref($custom_parent->{CUSTOM}) eq 'HASH' ?
        $custom_parent->{CUSTOM} : {};

    my @containers = ();
    foreach my $section ($self->sections()) {
        if ($section->{match}) {
            my $re_match = qr/^$section->{match}$/;
            next if !$device->type && $section->{match} eq 'COMPUTER';
            next if $device->type !~ $re_match;
        }
        # Prepare CONTAINER node with plugin version
        my $container = {
            -plugin     => "toolbox",
            -version    => $GLPI::Agent::HTTP::Server::ToolBox::VERSION,
            ID          => $section->{id},
        };
        # Then include a FIELDS node
        my $fields = $container->{FIELDS} = {};
        my %fields = ();
        foreach my $field ($self->fields()) {
            next unless $field->{section} eq $section->{name};
            $fields{$field->{from}} = $field->{prefix}.$field->{name};
        }
        foreach my $key (keys(%fields)) {
            next if $device->noedit($fields{$key});
            my $value = $device->get($fields{$key});
            next unless length($value);
            $fields->{$key} = decode_entities($value);
        }
        push @containers, $container if keys(%{$fields});
    }

    # Store containers in XML or keep XML clean
    if (@containers) {
        $custom->{CONTAINER} = \@containers;
        $custom_parent->{CUSTOM} = $custom;
    } elsif ($custom->{CONTAINER}) {
        delete $custom->{CONTAINER};
        delete $custom_parent->{CUSTOM} unless keys(%{$custom_parent->{CUSTOM}});
    }
}

sub _prepare_custom_fields {
    my ($self, $custom_fields) = @_;

    my $fields = $self->{_fields} = [];
    my %sections = ();

    my %types_bindings = (
        text            => "text",
        textarea        => "textarea",
        number          => "number",
        url             => "text",
        dropdown        => "select",
        yesno           => "select",
        date            => "date",
        datetime        => "datetime",
        dropdownuser    => "select",
        header          => "header",
    );

    my %itemtypes_binding = (
        NetworkEquipment    => 'NETWORKING|STORAGE',
        Printer             => 'PRINTER',
        Computer            => 'COMPUTER',
    );

    my $prefix = "custom/";

    my @custom_fields = sort { $custom_fields->{$a}->{id} <=> $custom_fields->{$b}->{id} }
        keys(%{$custom_fields});
    foreach my $name (@custom_fields) {
        my $section = $custom_fields->{$name};
        unless ($section->{fields} && @{$section->{fields}}) {
            $self->{logger}->info("Skipping $name fields: no fields definition");
            next
        }
        $sections{$section} = {
            name    => $name,
            title   => encode('UTF-8', encode_entities($section->{name})),
            index   => 100 + $self->{_section_index}++,
            prefix  => $prefix,
            id      => $section->{id},
        };
        if ($section->{itemtype} && $itemtypes_binding{$section->{itemtype}}) {
            $sections{$section}->{match} = $itemtypes_binding{$section->{itemtype}};
        }
        my @fields = sort { $a->{ranking} <=> $b->{ranking} } @{$section->{fields}};
        my $index = 100;
        foreach my $field (@fields) {
            unless (defined($field->{xml_node}) && length($field->{xml_node})) {
                $self->{logger}->info("Skipping field without name: xml_node definition missing");
                next;
            }
            my $this = {
                name    => lc($field->{xml_node}),
                section => $name,
                type    => $types_bindings{$field->{type}} || 'read-only',
                from    => uc($field->{xml_node}),
                text    => encode('UTF-8', encode_entities($field->{label} || $field->{xml_node})),
                column  => $index,
                editcol => $index % 2,
                index   => $index, # Used to order field in edit mode and in a given edit column
                noedit  => 0,
                default => $field->{default_value} || '',
                options => $field->{possible_value},
                prefix  => $prefix,
            };
            # Handle possible values case
            if (ref($field->{possible_value}) eq 'ARRAY') {
                $this->{options} = [];
                foreach my $option (sort { $a->{id} <=> $b->{id} } @{$field->{possible_value}}) {
                    push @{$this->{options}}, {
                        value => encode('UTF-8', encode_entities(defined($option->{text}) ? $option->{text} : $option->{value})),
                        title => encode('UTF-8', encode_entities($option->{title} || '')),
                        id    => $option->{id},
                    };
                }
                if (defined($this->{default}) && length($this->{default})) {
                    my ($default) = grep { int($_->{id}) == int($this->{default}) } @{$field->{possible_value}};
                    $this->{default} = encode('UTF-8', encode_entities(defined($default->{text}) ? $default->{text} : $default->{value}));
                }
            }
            # On header, increment index to next pair integer
            if ($this->{type} eq 'header') {
                $this->{editcol} = 0;
                $this->{index} = $index += $index % 2;
                $index += 2;
            } else {
                $index++;
            }
            push @{$fields}, $this;
        }
    }

    $self->{_sections} = [ sort { $a->{index} <=> $b->{index} } values(%sections) ];
}

1;
