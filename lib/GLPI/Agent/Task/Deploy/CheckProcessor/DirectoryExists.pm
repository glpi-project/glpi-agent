package GLPI::Agent::Task::Deploy::CheckProcessor::DirectoryExists;

use strict;
use warnings;

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

sub prepare {
    my ($self) = @_;

    $self->on_failure($self->{path} . " directory is missing");
    $self->on_success($self->{path} . " directory exists");
}

sub success {
    my ($self) = @_;

    return -d $self->{path};
}

1;
