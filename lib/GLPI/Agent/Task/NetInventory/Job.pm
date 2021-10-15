package GLPI::Agent::Task::NetInventory::Job;

use strict;
use warnings;

use English qw(-no_match_vars);

use GLPI::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger          => $params{logger} || GLPI::Agent::Logger->new(),
        _params         => $params{params},
        _credentials    => $params{credentials},
        _devices        => $params{devices},
    };
    bless $self, $class;
}

sub pid {
    my ($self) = @_;
    return $self->{_params}->{PID} || 0;
}

sub timeout {
    my ($self) = @_;
    return $self->{_params}->{TIMEOUT} || 60;
}

sub max_threads {
    my ($self) = @_;
    return $self->{_params}->{THREADS_QUERY} || 1;
}

sub count {
    my ($self) = @_;
    return scalar(@{$self->{_devices}});
}

sub devices {
    my ($self) = @_;

    return @{$self->{_devices}};
}

sub credentials {
    my ($self) = @_;

    unless (defined($self->{_credentials})) {
        $self->{logger}->warning("No SNMP credential defined for this job");
        return {};
    }

    $self->{logger}->warning("No SNMP credential provided for this job")
        unless @{$self->{_credentials}};

    # index credentials by their ID
    return { map { $_->{ID} => $_ } @{$self->{_credentials}} };
}

1;
