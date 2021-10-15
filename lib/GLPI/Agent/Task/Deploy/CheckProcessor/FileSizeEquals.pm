package GLPI::Agent::Task::Deploy::CheckProcessor::FileSizeEquals;

use strict;
use warnings;

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

sub prepare {
    my ($self) = @_;

    $self->on_success($self->{path} . " expected file size: ".($self->{value}||'n/a'));
}

sub success {
    my ($self) = @_;

    $self->on_failure($self->{path} . " is missing");
    return 0 unless -f $self->{path};

    $self->on_failure("no value provided to check file size against");
    my $expected = $self->{value};
    return 0 unless (defined($expected));

    my @fstat = stat($self->{path});
    $self->on_failure($self->{path} . " file stat failure, $!");
    return 0 unless (@fstat);

    $self->on_failure("file size not found");
    my $size = $fstat[7];
    return 0 unless (defined($size));

    $self->on_failure($self->{path} . " has wrong file size: $size vs $expected");
    return ( $size == $expected );
}

1;
