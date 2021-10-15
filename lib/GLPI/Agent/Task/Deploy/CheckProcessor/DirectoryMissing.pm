package GLPI::Agent::Task::Deploy::CheckProcessor::DirectoryMissing;

use strict;
use warnings;

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

sub prepare {
    my ($self) = @_;

    $self->on_failure($self->{path} . " directory exists");
    $self->on_success($self->{path} . " directory is missing");
}

sub success {
    my ($self) = @_;

    return ! -d $self->{path};
}

1;
