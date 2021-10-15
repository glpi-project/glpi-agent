package FusionInventory::Agent::Task::Deploy::CheckProcessor::FileMissing;

use strict;
use warnings;

use parent "FusionInventory::Agent::Task::Deploy::CheckProcessor";

sub prepare {
    my ($self) = @_;

    $self->on_failure($self->{path} . " file exists");
    $self->on_success($self->{path} . " file is missing");
}

sub success {
    my ($self) = @_;

    return ! -f $self->{path};
}

1;
