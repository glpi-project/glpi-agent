package GLPI::Agent::Task::Deploy::CheckProcessor::FileSizeLower;

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
    my $greater = $self->{value};
    return 0 unless (defined($greater));

    my @fstat = stat($self->{path});
    $self->on_failure($self->{path} . " file stat failure, $!");
    return 0 unless (@fstat);

    $self->on_failure("file size not found");
    my $size = $fstat[7];
    return 0 unless (defined($size));

    $self->on_failure($self->{path} . " file size not lower: $size >= $greater");
    $self->on_success($self->{path} . " file size is lower: $size < $greater");
    return ( $size < $greater );
}

1;
