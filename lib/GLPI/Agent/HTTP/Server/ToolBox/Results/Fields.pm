package GLPI::Agent::HTTP::Server::ToolBox::Results::Fields;

use strict;
use warnings;

use HTML::Entities;

sub new {
    my ($class, %params) = @_;

    my ($name) = $class =~ /::(\w+)$/;

    # We are just a base class without fields
    return if $name eq 'Fields';

    my $self = {
        logger  => $params{results}->{logger} ||
                    GLPI::Agent::Logger->new(),
        results => $params{results},
        _name   => $name,
    };

    bless $self, $class;

    return $self;
}

sub name {
    my ($self) = @_;
    return $self->{_name};
}

sub any { 0 }

sub order { 0 }

sub sections {}

sub fields {
    my ($self) = @_;

    return unless $self->{_fields} && @{$self->{_fields}};

    return @{$self->{_fields}};
}

sub analyze {}

sub update_xml {}

sub update_template_hash {}

sub fields_common_analysis {
    my ($self, $infos) = @_;

    my %fields;

    foreach my $field ($self->fields()) {

        my $name = $field->{name}
            or next;

        my $from = $field->{from};
        my $ref = $field->{tag} ? $infos->{$field->{tag}} : $infos;
        my $value;
        if (ref($from)) {
            foreach my $key (@{$from}) {
                $value = $ref->{$key};
                last if defined($value);
            }
        } elsif ($from) {
            $value = $ref->{$from};
        }
        $value = $field->{default}
            if ($field->{default} && !defined($value));
        next unless defined($value);
        $fields{$name} = decode_entities($value);
    }

    return \%fields;
}

1;
