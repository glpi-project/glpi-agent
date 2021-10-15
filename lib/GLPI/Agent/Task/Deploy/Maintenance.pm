package FusionInventory::Agent::Task::Deploy::Maintenance;

use strict;
use warnings;

use FusionInventory::Agent::Logger;
use FusionInventory::Agent::Storage;
use FusionInventory::Agent::Task::Deploy::Datastore;

sub new {
    my ($class, %params) = @_;

    die 'no target parameter\n' unless $params{target};
    die 'no config parameter\n' unless $params{config};

    my $self = {
        logger       => $params{logger} ||
                        FusionInventory::Agent::Logger->new(),
        config       => $params{config},
        target       => $params{target},
    };
    bless $self, $class;

    return $self;
}

sub doMaintenance {
    my ($self) = @_;

    my $folder = $self->{target}->getStorage()->getDirectory()
        or return;

    $folder .= '/deploy';
    return unless -d $folder;

    my $datastore = FusionInventory::Agent::Task::Deploy::Datastore->new(
        config => $self->{config},
        path   => $folder,
        logger => $self->{logger}
    );

    $datastore->cleanUp( force => $datastore->diskIsFull() );
}

1;

__END__

=head1 NAME

FusionInventory::Agent::Task::Deploy::Maintenance - Maintenance for Deploy task

=head1 DESCRIPTION

This module provides the Maintenance run function to cleanup Deploy environment.

=head1 FUNCTIONS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<config>

=item I<target>

=back

=head2 doMaintenance()

Cleanup the deploy datastore associated with the target.
