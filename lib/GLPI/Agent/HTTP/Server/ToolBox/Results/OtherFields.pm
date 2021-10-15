package GLPI::Agent::HTTP::Server::ToolBox::Results::OtherFields;

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

    return $self->_analyse_other_fields();
}

sub any { 1 }

sub order { 11 }

sub sections {
    return {
        name    => "other_fields",
        index   => 2,
        title   => "Other fields"
    };
}

sub analyze {
    my ($self, $name, $tree) = @_;

    return unless $name && $tree;

    my $request = $tree && $tree->{REQUEST}
        or return;

    my %fields;

    foreach my $field ($self->fields()) {

        my $fieldname = $field->{name}
            or next;

        my $node = $request;
        my @leafs = @{$field->{leafs}};
        foreach my $leaf (@leafs) {
            if (ref($node) eq 'ARRAY') {
                my $filter = $field->{filter};
                if ($filter) {
                    my $found = 0;
                    my @keys = keys(%{$filter});
                    foreach my $elem (@{$node}) {
                        next unless ref($elem) eq 'HASH';
                        my $match = grep { defined($elem->{$_}) && $elem->{$_} =~ $filter->{$_} } @keys;
                        if ($match == @keys) {
                            $node = $elem->{$leaf};
                            $found++;
                            last;
                        }
                    }
                    # Finally take first node on no match
                    $node = shift @{$node} unless $found;
                } else {
                    # Take first node without filter
                    $node = shift @{$node};
                }
                $node = $node->{$leaf}
                    if (ref($node) eq 'HASH' && $node->{$leaf});
            } elsif (ref($node) eq 'HASH' && $node->{$leaf}) {
                $node = $node->{$leaf};
            } else {
                undef $node;
                last;
            }
        }
        next unless $node;

        $fields{$fieldname} = $node unless ref($node);
    }

    # Forbid any edition on these fields
    map { $fields{_noedit}->{$_} = 1 } keys(%fields);

    return \%fields;
}

sub _analyse_other_fields {
    my ($self) = @_;

    # Initialize other fields
    my $yaml_configuration = $self->{results}->yaml('configuration')
        or return;

    my $other_fields_config = $yaml_configuration->{'other_fields'}
        or return;

    # Reset config
    delete $self->{_fields};

    # Parse other fields
    my $index = 50;
    foreach my $config (split("\n", $other_fields_config)) {
        $config =~ s/\r+$//;
        my ($name, $text, $node, $filter) = split(";", $config);
        next unless $name && $text && $node;
        if ($filter) {
            my %filters;
            foreach my $criteria (split(",", $filter)) {
                my ($key, $value) = split(/=/, $criteria);
                next unless $key && $value;
                $filters{$key} = qr/^$value$/;
            }
            $filter = \%filters;
        }
        push @{$self->{_fields}}, {
            name    => $name,
            text    => encode('UTF-8', encode_entities($text)),
            section => "other_fields",
            type    => "readonly",
            leafs   => [ split(",",$node) ],
            filter  => $filter || {},
            column  => $index,
            editcol => $index % 2,
            index   => $index, # Used to order field in edit mode and in a given edit column
            noedit  => 1,
        };
        $index ++;
    }

    return unless $self->{_fields};

    return $self;
}

1;
