package GLPI::Agent::Task::Deploy::CheckProcessor::FreeSpaceGreater;

use strict;
use warnings;

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

use GLPI::Agent::Task::Deploy::DiskFree;

sub prepare {
}

sub success {
    my ($self) = @_;
    $self->on_failure("no value provided to check free space against");
    my $lower = $self->{value};
    return 0 unless (defined($lower));

    my $freespace = getFreeSpace(
        logger => $self->{logger},
        path   => $self->{path}
    );
    $self->on_failure($self->{path} . " free space not found, $!");
    return 0 unless (defined($freespace));

    $self->on_failure($self->{path} . " free space not greater: $freespace <= $lower");
    $self->on_success($self->{path} . " free space is greater: $freespace > $lower");
    return ( $freespace > $lower );
}

1;
