package GLPI::Agent::Task::Inventory::MacOS::Networks;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Unix;

use constant    category    => "network";

sub isEnabled {
    return canRun('ifconfig');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $routes = getRoutingTable(logger => $logger);
    my $default = $routes->{'0.0.0.0'};

    my $interfaces = _getInterfaces(logger => $logger);
    foreach my $interface (@{$interfaces}) {
        # if the default gateway address and the interface address belongs to
        # the same network, that's the gateway for this network
        $interface->{IPGATEWAY} = $default if isSameNetwork(
            $default, $interface->{IPADDRESS}, $interface->{IPMASK}
        );

        $inventory->addEntry(
            section => 'NETWORKS',
            entry   => $interface
        );
    }

    $inventory->setHardware({
        DEFAULTGATEWAY => $default
    });
}

sub _getInterfaces {
    my (%params) = @_;

    my $interfaces = _parseIfconfig(
        command     => '/sbin/ifconfig -a',
        netsetup    => _parseNetworkSetup(%params),
        %params
    );

    foreach my $interface (@{$interfaces}) {
        next unless $interface->{IPADDRESS} && $interface->{IPMASK};
        $interface->{IPSUBNET} = getSubnetAddress(
            $interface->{IPADDRESS},
            $interface->{IPMASK}
        );
    }

    return $interfaces;
}

sub _parseNetworkSetup {
    my (%params) = @_;

    # Can be provided by unittest
    return $params{netsetup} if $params{netsetup};

    my @lines = getAllLines(
        command => 'networksetup -listallhardwareports',
        %params
    );
    return unless @lines;

    my $netsetup;
    my $interface;

    foreach my $line (@lines) {
        if ($line =~ /^Hardware Port: (.+)$/) {
            $interface = {
                description => $1
            };
        } elsif ($line =~ /^Device: (.+)$/) {
            $netsetup->{$1} = $interface;
        } elsif ($line =~ /^Ethernet Address: (.+)$/) {
            $interface->{macaddr} = $1;
        } elsif ($line =~ /^VLAN Configurations/) {
            last;
        }
    }

    return $netsetup;
}

sub _parseIfconfig {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $netsetup = $params{netsetup} || {};
    my @interfaces;
    my $interface;

    foreach my $line (@lines) {
        if ($line =~ /^(\S+):/) {
            # new interface
            push @interfaces, $interface if $interface;
            $interface = {
                STATUS      => 'Down',
                DESCRIPTION => $netsetup->{$1} ? $netsetup->{$1}->{description} : $1,
                VIRTUALDEV  => $netsetup->{$1} ? 0 : 1
            };
            $interface->{MACADDR} = $netsetup->{$1}->{macaddr}
                if $netsetup->{$1} && $netsetup->{$1}->{macaddr};
        }

        if ($line =~ /inet ($ip_address_pattern)/) {
            $interface->{IPADDRESS} = $1;
        }
        if ($line =~ /inet6 (\S+)/) {
            $interface->{IPADDRESS6} = $1;
            # Drop the interface from the address. e.g:
            # fe80::1%lo0
            # fe80::214:51ff:fe1a:c8e2%fw0
            $interface->{IPADDRESS6} =~ s/%.*$//;
        }
        if ($line =~ /netmask 0x($hex_ip_address_pattern)/) {
            $interface->{IPMASK} = hex2canonical($1);
        }
        if ($line =~ /(?:address:|ether|lladdr) ($mac_address_pattern)/) {
            $interface->{MACADDR} = $1;
        }
        if ($line =~ /mtu (\S+)/) {
            $interface->{MTU} = $1;
        }
        if ($line =~ /media (\S+)/) {
            $interface->{TYPE} = $1;
        }
        if ($line =~ /media: \S+ \((\d+)baseTX <.*>\)/) {
            $interface->{SPEED} = $1;
        }
        if ($line =~ /status:\s+active/i) {
            $interface->{STATUS} = 'Up';
        }
        if ($line =~ /supported\smedia:/) {
            $interface->{VIRTUALDEV} = 0;
        }
    }

    # last interface
    push @interfaces, $interface if $interface;

    return \@interfaces;
}

1;
