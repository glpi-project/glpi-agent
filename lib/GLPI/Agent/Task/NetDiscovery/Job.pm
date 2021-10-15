package GLPI::Agent::Task::NetDiscovery::Job;

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
        _ranges         => $params{ranges},
        _snmpwalk       => $params{file},
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
    return $self->{_params}->{THREADS_DISCOVERY} || 1;
}

sub ranges {
    my ($self) = @_;

    my @ranges = ();

    foreach my $range (@{$self->{_ranges}}) {
        push @ranges, {
            ports   => _getSNMPPorts($range->{PORT}),
            domains => _getSNMPProtocols($range->{PROTOCOL}),
            entity  => $range->{ENTITY},
            start   => $range->{IPSTART},
            end     => $range->{IPEND},
            walk    => $self->{_snmpwalk},
        };
    }

    return @ranges;
}

sub getValidCredentials {
    my ($self) = @_;

    my @credentials;

    foreach my $credential (@{$self->{_credentials}}) {
        if ($credential->{VERSION} eq '3') {
            # a user name is required
            next unless $credential->{USERNAME};
            # DES support is required
            next unless Crypt::DES->require();
        } else {
            next unless $credential->{COMMUNITY};
        }
        push @credentials, $credential;
    }

    $self->{logger}->warning("No valid SNMP credential defined for this scan")
        unless @credentials;

    return \@credentials;
}

sub _getSNMPPorts {
    my ($ports) = @_;

    return [] unless $ports;

    # Given ports can be an array of strings or just a string and each string
    # can be a comma separated list of ports
    my @given_ports = map { split(/\s*,\s*/, $_) }
        ref($ports) eq 'ARRAY' ? @{$ports} : ($ports) ;

    # Be sure to only keep valid and uniq ports
    my %ports = map { $_ => 1 } grep { $_ && $_ > 0 && $_ < 65536 } @given_ports;

    return [ sort keys %ports ];
}


sub _getSNMPProtocols {
    my ($protocols) = @_;

    return [] unless $protocols;

    # Supported protocols can be used as '-domain' option for Net::SNMP session
    my @supported_protocols = (
        'udp/ipv4',
        'udp/ipv6',
        'tcp/ipv4',
        'tcp/ipv6'
    );

    # Given protocols can be an array of strings or just a string and each string
    # can be a comma separated list of protocols
    my @given_protocols = map { split(/\s*,\s*/, $_) }
        ref($protocols) eq 'ARRAY' ? @{$protocols} : ($protocols) ;

    my @protocols = ();
    my %protocols = map { lc($_) => 1 } grep { $_ } @given_protocols;

    # Manage to list and filter protocols to use in @supported_protocols order
    foreach my $proto (@supported_protocols) {
        if ($protocols{$proto}) {
            push @protocols, $proto;
        }
    }

    return \@protocols;
}

1;
