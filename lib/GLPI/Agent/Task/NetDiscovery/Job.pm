package GLPI::Agent::Task::NetDiscovery::Job;

use strict;
use warnings;

use English qw(-no_match_vars);

use Net::IP;

use GLPI::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger          => $params{logger} || GLPI::Agent::Logger->new(),
        _params         => $params{params},
        _credentials    => $params{credentials},
        _ranges         => $params{ranges},
        _snmpwalk       => $params{file},
        _netscan        => $params{netscan} // 0,
        _control        => $params{showcontrol} // 0,
        _localtask      => $params{localtask} // 0,
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

sub netscan {
    my ($self) = @_;
    return $self->{_netscan};
}

sub control {
    my ($self) = @_;
    return $self->{_control};
}

sub localtask {
    my ($self) = @_;
    return $self->{_localtask};
}

sub getQueueParams {
    my ($self, $range) = @_;

    my $start = $range->{start};
    my $end   = $range->{end};

    my $block = Net::IP->new( "$start-$end" );
    if (!$block || !$block->ip() || $block->{binip} !~ /1/) {
        $self->{logger}->error(
            "IPv4 range not supported by Net::IP: $start-$end"
        );
        return 0;
    }

    unless ($block->size()) {
        $self->{logger}->error("Skipping empty range: $start-$end");
        return 0;
    }

    $self->{logger}->debug("initializing block $start-$end");

    $range->{block} = $block;

    my $params = {
        size    => $block->size()->numify(),
        range   => $range
    };

    return 1, $params;
}

sub updateQueue {
    my ($self, %params) = @_;

    $self->{_queue}->{size} += $params{size};
    push @{$self->{_queue}->{ranges}}, $params{range} if $params{range};
}

sub queuesize {
    my ($self) = @_;

    return 0 unless $self->{_queue};

    return $self->{_queue}->{size} // 0;
}

sub started {
    my ($self) = @_;

    return 0 unless $self->{_queue};

    return 1 if $self->{_queue}->{started};

    # Be sure to return true next time
    $self->{_queue}->{started}++;
    return 0;
}

sub done {
    my ($self) = @_;

    return 0 unless $self->{_queue};

    $self->{_queue}->{in_queue} --;
    $self->{_queue}->{done} ++;

    return $self->{_queue}->{done} >= $self->{_queue}->{size} ? 1 : 0;
}

sub max_in_queue {
    my ($self) = @_;

    return 0 unless $self->{_queue};

    return $self->{_queue}->{in_queue} >= $self->max_threads() ? 1 : 0;
}

sub range {
    my ($self) = @_;

    return unless $self->{_queue};

    return $self->{_queue}->{ranges}->[0];
}

sub nextip {
    my ($self) = @_;

    return unless $self->{_queue};

    my $range = $self->{_queue}->{ranges}->[0];
    my $block = $range->{block};
    my $blockip = $block->ip();
    # Still update block and handle range list
    $range->{block} = $block + 1;
    shift @{$self->{_queue}->{ranges}} unless $range->{block};

    $self->{_queue}->{in_queue}++ if $blockip;

    return $blockip;
}

sub ranges {
    my ($self) = @_;

    # After _queue has been defined, return the queue ranges count
    return scalar(@{$self->{_queue}->{ranges}}) if $self->{_queue};

    $self->{_queue} = {
        in_queue            => 0,
        snmp_credentials    => $self->_getValidCredentials() // [],
        ranges              => [],
        size                => 0,
        done                => 0,
    };

    my @ranges = ();

    foreach my $range (@{$self->{_ranges}}) {
        my $thisrange = {
            name    => $range->{NAME} // "",
            ports   => _getSNMPPorts($range->{PORT}),
            domains => _getSNMPProtocols($range->{PROTOCOL}),
            entity  => $range->{ENTITY},
            start   => $range->{IPSTART},
            end     => $range->{IPEND},
            walk    => $self->{_snmpwalk},
        };
        # Support ToolBox model where credentials are linked to range
        if ($range->{NAME}) {
            $thisrange->{credentials} = $self->_getValidCredentials($range->{NAME});
        }
        push @ranges, $thisrange;
    }

    return @ranges;
}

sub snmp_credentials {
    my ($self) = @_;

    return unless $self->{_queue};

    return $self->{_queue}->{snmp_credentials};
}

sub _getValidCredentials {
    my ($self, $name) = @_;

    my @credentials;

    # Support ToolBox model where credentials are linked to range
    return if $name && ref($self->{_credentials}) ne 'HASH';
    return if !$name && ref($self->{_credentials}) eq 'HASH';

    my $credentials = $name ? $self->{_credentials}->{$name} : $self->{_credentials};

    my ($snmp, $valid_snmp, $invalid_snmp, $remote, $valid_remote, $invalid_remote) = (0, 0, 0, 0, 0, 0);
    foreach my $credential (@{$credentials}) {
        next if $credential->{TYPE} && $credential->{TYPE} !~ /^snmp|esx|ssh|winrm$/;
        # Support no credentials type as legacy snmp credentials
        if (!$credential->{TYPE} || $credential->{TYPE} eq 'snmp') {
            $snmp++;
            if ($credential->{VERSION} eq '3') {
                # a user name is required
                unless ($credential->{USERNAME}) {
                    $self->{logger}->warning("No username defined for a SNMPv3 credential")
                        unless $invalid_snmp++;
                    $invalid_snmp++;
                    next;
                }
                # DES support is required
                unless (Crypt::DES->require()) {
                    $self->{logger}->warning("Crypt::DES perl module required for SNMPv3 credentials")
                        unless $invalid_snmp++;
                    $invalid_snmp++;
                    next;
                }
            } elsif (!$credential->{COMMUNITY}) {
                $self->{logger}->warning("No community defined for a credential")
                    unless $invalid_snmp++;
                $invalid_snmp++;
                next;
            }
            $valid_snmp++;
        } else {
            $remote++;
            unless (defined($credential->{USERNAME}) && length($credential->{USERNAME})) {
                $self->{logger}->warning("No username defined for a $credential->{TYPE} credential")
                    unless $invalid_remote++;
                $invalid_remote++;
                next;
            }
            if ($credential->{TYPE} =~ /^esx|winrm$/ && (!defined($credential->{PASSWORD}) || !length($credential->{PASSWORD}))) {
                $self->{logger}->warning("No password defined for a $credential->{TYPE} credential")
                    unless $invalid_remote++;
                $invalid_remote++;
                next;
            }
            if ($credential->{TYPE} =~ /^ssh|winrm$/ && defined($credential->{PORT}) && ($credential->{PORT} !~ /^\d+$/ || ($credential->{PORT} < 0 || $credential->{PORT} > 65535))) {
                $self->{logger}->warning("Not valid port defined for a $credential->{TYPE} credential")
                    unless $invalid_remote++;
                $invalid_remote++;
                next;
            }
            $valid_remote++;
        }
        push @credentials, $credential;
    }

    $self->{logger}->warning("No valid SNMP credential defined for this scan")
        unless !$snmp || $valid_snmp;

    $self->{logger}->warning("No valid remote credential defined for this scan")
        unless !$remote || $valid_remote;

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
        'udp',
        'udp/ipv4',
        'udp/ipv6',
        'tcp',
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
