package GLPI::Agent::Task::Deploy::CheckProcessor::FileSizeGreater;

use strict;
use warnings;

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

sub prepare {
}

sub success {
    my ($self) = @_;

    $self->on_failure($self->{path} . " is missing");
    return 0 unless -f $self->{path};

    $self->on_failure("no value provided to check file size against");
    my $lower = $self->{value};
    return 0 unless (defined($lower));

    my @fstat = stat($self->{path});
    $self->on_failure($self->{path} . " file stat failure, $!");
    return 0 unless (@fstat);

    $self->on_failure("file size not found");
    my $size = $fstat[7];
    return 0 unless (defined($size));

    $self->on_failure($self->{path} . " file size not greater: $size <= $lower");
    $self->on_success($self->{path} . " file size is greater: $size > $lower");
    return ( $size > $lower );
}

1;
