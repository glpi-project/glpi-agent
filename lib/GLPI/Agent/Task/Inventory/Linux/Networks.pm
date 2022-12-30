package GLPI::Agent::Task::Inventory::Linux::Networks;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Unix;
use GLPI::Agent::Tools::Linux;

use constant    category    => "network";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $routes = getRoutingTable(command => 'netstat -nr', logger => $logger);
    my $default = $routes->{'0.0.0.0'};

    my @interfaces = _getInterfaces(logger => $logger);
    foreach my $interface (@interfaces) {
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

    my $logger = $params{logger};

    my @interfaces = _getInterfacesBase(logger => $logger);

    foreach my $interface (@interfaces) {
        $interface->{IPSUBNET} = getSubnetAddress(
            $interface->{IPADDRESS},
            $interface->{IPMASK}
        );

        $interface->{IPDHCP} = getIpDhcp(
            $logger,
            $interface->{DESCRIPTION}
        );

        # check if it is a physical interface
        if (has_folder("/sys/class/net/$interface->{DESCRIPTION}/device") &&
           !has_folder("/sys/devices/virtual/net/$interface->{DESCRIPTION}")) {
            my $info = _getUevent($interface->{DESCRIPTION});
            $interface->{DRIVER}  = $info->{DRIVER}
                if $info->{DRIVER};
            $interface->{PCISLOT} = $info->{PCI_SLOT_NAME}
                if $info->{PCI_SLOT_NAME};
            $interface->{PCIID} =
                $info->{PCI_ID} . ':' . $info->{PCI_SUBSYS_ID}
                if $info->{PCI_SUBSYS_ID} && $info->{PCI_ID};

            $interface->{VIRTUALDEV} = 0;

            # check if it is a wifi interface, otherwise assume ethernet
            if (has_folder("/sys/class/net/$interface->{DESCRIPTION}/wireless")) {
                $interface->{TYPE} = 'wifi';
                my $info = _parseIwconfig(name => $interface->{DESCRIPTION});
                $interface->{WIFI_MODE}    = $info->{mode};
                $interface->{WIFI_SSID}    = $info->{SSID};
                $interface->{WIFI_BSSID}   = $info->{BSSID};
                $interface->{WIFI_VERSION} = $info->{version};
            } elsif (has_file("/sys/class/net/$interface->{DESCRIPTION}/mode")) {
                $interface->{TYPE} = 'infiniband';
            } else {
                $interface->{TYPE} = 'ethernet';
            }

        } else {
            $interface->{VIRTUALDEV} = 1;

            if ($interface->{DESCRIPTION} eq 'lo') {
                $interface->{TYPE} = 'loopback';
            }

            if ($interface->{DESCRIPTION} =~ m/^ppp/) {
                $interface->{TYPE} = 'dialup';
            }

            # check if it is an alias or a tagged interface
            if ($interface->{DESCRIPTION} =~ m/^([\w\d]+)[:.]\d+$/) {
                $interface->{TYPE} = 'alias';
                $interface->{BASE} = $1;
             }
            # check if is is a bridge
            if (has_folder("/sys/class/net/$interface->{DESCRIPTION}/brif")) {
                $interface->{SLAVES} = _getSlaves($interface->{DESCRIPTION});
                $interface->{TYPE}   = 'bridge';
            }

            # check if it is a bonding master
            if (has_folder("/sys/class/net/$interface->{DESCRIPTION}/bonding")) {
                $interface->{SLAVES} = _getSlaves($interface->{DESCRIPTION});
                $interface->{TYPE}   = 'aggregate';
            }
        }

        # check if it is a bonding slave
        if (has_folder("/sys/class/net/$interface->{DESCRIPTION}/bonding_slave")) {
            $interface->{MACADDR} = getFirstMatch(
                command => "ethtool -P $interface->{DESCRIPTION}",
                pattern => qr/^Permanent address: ($mac_address_pattern)$/,
                logger  => $logger
            );
        }

        if (defined($interface->{STATUS}) && $interface->{STATUS} eq 'Up') {
            if (canRead("/sys/class/net/$interface->{DESCRIPTION}/speed")) {
                my $speed = getFirstLine(
                    file => "/sys/class/net/$interface->{DESCRIPTION}/speed"
                );
                $interface->{SPEED} = $speed if $speed;
            }
            # On older kernels, we should try ethtool system call for speed
            # but don't try this method on virtual dev
            if (!$interface->{SPEED} && !$interface->{VIRTUALDEV}) {
                $logger->debug("looking for interface speed from syscall for $interface->{DESCRIPTION}:");
                my $infos = getInterfacesInfosFromIoctl(
                    interface => $interface->{DESCRIPTION},
                    logger    => $logger
                );
                if ($infos && $infos->{SPEED}) {
                    $logger->debug_result(
                        action => 'retrieving interface speed from syscall',
                        data   => $infos->{SPEED}
                    );
                    $interface->{SPEED} = $infos->{SPEED};
                } else {
                    $logger->debug_result(
                        action => 'retrieving interface speed from syscall',
                        status => 'syscall failed'
                    );
                }
            }
        } else {
            # Report zero speed in case the interface went from up to down
            # or the server has non-zero interface speed
            $interface->{SPEED} = 0;
        }
    }

    return @interfaces;
}

sub _getInterfacesBase {
    my (%params) = @_;

    my $logger = $params{logger};
    $logger->debug("retrieving interfaces list:");

    if (canRun('/sbin/ip')) {
        my @interfaces = getInterfacesFromIp(logger => $logger);
        $logger->debug_result(
            action => 'running /sbin/ip command',
            data   => scalar @interfaces
        );
        return @interfaces if @interfaces;
    } else {
        $logger->debug_result(
            action => 'running /sbin/ip command',
            status => 'command not available'
        );
    }

    if (canRun('/sbin/ifconfig')) {
        my @interfaces = getInterfacesFromIfconfig(logger => $logger);
        $logger->debug_result(
            action => 'running /sbin/ifconfig command',
            data   => scalar @interfaces
        );
        return @interfaces if @interfaces;
    } else {
        $logger->debug_result(
            action => 'running /sbin/ifconfig command',
            status => 'command not available'
        );
    }

    return;
}

sub _getSlaves {
    my ($name) = @_;

    my @slaves =
        map { $_ =~ /\/lower_(\w+)$/ }
        Glob("/sys/class/net/$name/lower_*");

    return join (",", @slaves);
}

sub _getUevent {
    my ($name) = @_;

    my $file = "/sys/class/net/$name/device/uevent";
    my @lines = getAllLines(file => $file)
        or return;

    my $info;
    foreach my $line (@lines) {
        next unless $line =~ /^(\w+)=(\S+)$/;
        $info->{$1} = $2;
    }

    return $info;
}

sub _parseIwconfig {
    my (%params) = @_;

    $params{command} = "iwconfig $params{name}" if $params{name};
    my @lines = getAllLines(
        %params,
        command => $params{name} ? "iwconfig $params{name}" : undef
    );
    return unless @lines;

    my $info;
    foreach my $line (@lines) {
        $info->{version} = $1
            if $line =~ /IEEE (\S+)/;
        $info->{SSID} = $1
            if $line =~ /ESSID:"([^"]+)"/;
        $info->{mode} = $1
            if $line =~ /Mode:(\S+)/;
        $info->{BSSID} = $1
            if $line =~ /Access Point: ($mac_address_pattern)/;
    }

    return $info;
}

1;
