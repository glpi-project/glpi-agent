package GLPI::Agent::Task::Inventory::BSD::Networks;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Unix;
use GLPI::Agent::Tools::BSD;

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

    my @interfaces = getInterfacesFromIfconfig(
        logger => $params{logger}
    );

    foreach my $interface (@interfaces) {
        $interface->{IPSUBNET} = getSubnetAddress(
            $interface->{IPADDRESS},
            $interface->{IPMASK}
        );

        $interface->{IPDHCP} = getIpDhcp(
            $params{logger},
            $interface->{DESCRIPTION}
        );

        if ($interface->{DESCRIPTION} =~ m/^(lo|vboxnet|vmnet|vtnet|sit|tun|pflog|pfsync|enc|strip|plip|sl|ppp|faith)/) {
            $interface->{VIRTUALDEV} = 1;

            if ($interface->{DESCRIPTION} =~ m/^lo/) {
                $interface->{TYPE} = 'loopback';
            }

            if ($interface->{DESCRIPTION} =~ m/^ppp/) {
                $interface->{TYPE} = 'dialup';
            }
        } else {
            $interface->{VIRTUALDEV} = 0;
        }
    }

    return @interfaces;
}

1;
