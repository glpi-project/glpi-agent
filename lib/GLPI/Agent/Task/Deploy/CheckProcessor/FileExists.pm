package GLPI::Agent::Task::Deploy::CheckProcessor::FileExists;

use strict;
use warnings;

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

sub prepare {
    my ($self) = @_;

    $self->on_failure($self->{path} . " file is missing");
    $self->on_success($self->{path} . " file exists");
}

sub success {
    my ($self) = @_;

    return -f $self->{path};
}

1;
