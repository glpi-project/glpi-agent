package GLPI::Agent::Task::NetInventory::Job;

use strict;
use warnings;

use English qw(-no_match_vars);

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;

sub new {
    my ($class, %params) = @_;

    my $devices = ref($params{devices}) eq 'ARRAY' ? $params{devices} : [];

    my $self = {
        logger          => $params{logger} || GLPI::Agent::Logger->new(),
        _params         => $params{params},
        _credentials    => $params{credentials},
        _devices        => $devices,
        _count          => scalar(@{$devices})
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
    return $self->{_count};
}

sub devices {
    my ($self) = @_;

    return @{$self->{_devices}};
}

sub skip_start_stop {
    my ($self) = @_;
    return $self->{_params}->{NO_START_STOP} // 0;
}

sub credential {
    my ($self, $id) = @_;

    my $credential;

    if (!defined($self->{_credentials})) {
        $self->{logger}->warning("No SNMP credential defined for this job");
    } elsif (!@{$self->{_credentials}}) {
        $self->{logger}->warning("No SNMP credential provided for this job")
    } else {
        ($credential) = first { $_->{ID} == $id } @{$self->{_credentials}}
            or $self->{logger}->warning("No SNMP credential with $id ID provided");
    }

    return $credential;
}

sub updateQueue {
    my ($self, $devices) = @_;

    return unless @{$devices};

    unless ($self->{_queue}) {
        $self->{_queue} = {
            in_queue        => 0,
            todo            => []
        };
    }

    push @{$self->{_queue}->{todo}}, @{$devices};
}

sub done {
    my ($self) = @_;

    return 0 unless $self->{_queue};

    $self->{_queue}->{in_queue} --;

    return $self->{_queue}->{in_queue} || @{$self->{_queue}->{todo}} ? 0 : 1;
}

sub no_more {
    my ($self) = @_;

    return 0 unless $self->{_queue};

    return @{$self->{_queue}->{todo}} ? 0 : 1 ;
}

sub max_in_queue {
    my ($self) = @_;

    return 0 unless $self->{_queue};

    return $self->{_queue}->{in_queue} >= $self->max_threads() ? 1 : 0;
}

sub nextdevice {
    my ($self) = @_;

    return unless $self->{_queue};

    my $device = shift @{$self->{_queue}->{todo}}
        or return;

    $self->{_queue}->{in_queue}++;

    return $device;
}
1;
