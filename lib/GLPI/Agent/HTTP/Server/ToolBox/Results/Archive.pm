package GLPI::Agent::HTTP::Server::ToolBox::Results::Archive;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;

    my ($name) = $class =~ /::(\w+)$/;

    # We are just a base class without fields
    return if $name eq 'Archive';

    my $self = {
        logger  => $params{results}->{logger} ||
                    GLPI::Agent::Logger->new(),
        results => $params{results},
        _name   => $name,
        _order  => 0,
        archive => 1,
    };

    bless $self, $class;

    return $self;
}

sub name {
    my ($self) = @_;
    return $self->{_name};
}

sub order {
    my ($self) = @_;
    return $self->{_order} || 0;
}

sub format {}

sub file_extension {
    my ($self) = @_;
    return $self->format;
}

sub archive {
    my ($self) = @_;
    my ($name) = $self->{_filename} =~ m|([^/]+)$|;
    return {
        name    => $name,
        path    => $self->{_filename},
        type    => $self->{_type},
    };
}

sub debug {
    my ($self, $debug) = @_;
    $self->{logger}->debug($debug);
}

1;
