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
    my $default = $routes->{'0.0.0.0'} // $routes->{'default'};

    my $interfaces = _getInterfaces(
        logger => $logger,
        glpi12_support => $inventory->supportsGlpiVersion('12.0.0')
    );
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

    if ($params{glpi12_support}) {
        my %statistics;
        my @netstat_lines = $params{netstat_file} 
            ? getAllLines(file => $params{netstat_file}, logger => $params{logger})
            : getAllLines(command => 'netstat -ib', logger => $params{logger});
        foreach my $line (@netstat_lines) {
            # Looking for Link layer line: Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes Coll
            if ($line =~ /^(\S+)\s+\d+\s+<Link#\d+>\s+(?:(?:[a-fA-F0-9:]+:[a-fA-F0-9:]+)\s+)?(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
                $statistics{$1} = {
                    ifinerrors  => $3,
                    ifinbytes   => $4,
                    ifouterrors => $6,
                    ifoutbytes  => $7,
                };
            }
        }

        foreach my $interface (@{$interfaces}) {
            my $sys_name = $interface->{_system_name} || $interface->{DESCRIPTION};
            if ($statistics{$sys_name}) {
                my $stat = $statistics{$sys_name};
                $interface->{IFINBYTES}   = $stat->{ifinbytes};
                $interface->{IFOUTBYTES}  = $stat->{ifoutbytes};
                $interface->{IFINERRORS}  = $stat->{ifinerrors};
                $interface->{IFOUTERRORS} = $stat->{ifouterrors};
            }
        }
    }

    my %wifi_rates;
    my $current_wifi_if;
    my @wdutil_lines = $params{wdutil_file}
        ? getAllLines(file => $params{wdutil_file}, logger => $params{logger})
        : getAllLines(command => 'wdutil info', logger => $params{logger});
    foreach my $line (@wdutil_lines) {
        if ($line =~ /Interface Name\s+:\s+(\S+)/) {
            $current_wifi_if = $1;
        } elsif ($current_wifi_if && $line =~ /Tx Rate\s+:\s+([\d\.]+)\s+Mbps/i) {
            $wifi_rates{$current_wifi_if} = int($1);
            undef $current_wifi_if;
        }
    }

    foreach my $interface (@{$interfaces}) {
        my $sys_name = $interface->{_system_name} || $interface->{DESCRIPTION};
        if ($wifi_rates{$sys_name} && !$interface->{SPEED}) {
            $interface->{SPEED} = $wifi_rates{$sys_name};
        }
    }

    foreach my $interface (@{$interfaces}) {
        delete $interface->{_system_name};
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
                STATUS       => 'Down',
                _system_name => $1,
                DESCRIPTION  => $netsetup->{$1} ? $netsetup->{$1}->{description} : $1,
                VIRTUALDEV   => $netsetup->{$1} ? 0 : 1
            };
            $interface->{MACADDR} = $netsetup->{$1}->{macaddr}
                if $netsetup->{$1} && $netsetup->{$1}->{macaddr};

            # Set port type
            if ($interface->{DESCRIPTION}) {
                if ($interface->{DESCRIPTION} =~ /^lo\d+$/) {
                    $interface->{TYPE} = 'loopback';
                } elsif ($interface->{DESCRIPTION} =~ /bridge/i) {
                    $interface->{TYPE} = 'bridge';
                } elsif ($interface->{DESCRIPTION} =~ /wi-?fi/i) {
                    $interface->{TYPE} = 'wifi';
                } elsif ($interface->{DESCRIPTION} =~ /bluetooth/i) {
                    $interface->{TYPE} = 'bluetooth';
                } elsif ($interface->{DESCRIPTION} =~ /phone/i) {
                    $interface->{TYPE} = 'dialup';
                } elsif ($interface->{DESCRIPTION} =~ /ethernet|thunderbolt|usb.*lan/i) {
                    $interface->{TYPE} = 'ethernet';
                }
            }
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
        if ($line =~ /media (\S+)/ && empty($interface->{TYPE})) {
            $interface->{TYPE} = $1;
        }
        if ($line =~ /media: \S+ \((?:(\d+)G)?(\d+)?base[^ ]* <.*>\)/i) {
            $interface->{SPEED} = $1 ? $1 * 1000 : $2;
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
