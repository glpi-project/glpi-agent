package GLPI::Agent::Task::Inventory::Linux::Networks::DockerMacvlan;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Cpanel::JSON::XS;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;

sub isEnabled {
    return canRun('docker');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @networks = _getMacvlanNetworks(logger => $logger) or return;

    foreach my $network (@networks) {
        my @interfaces = _getInterfaces(logger => $logger, networkId => $network);
        foreach my $interface (@interfaces) {
            $inventory->addEntry(
                section => 'NETWORKS',
                entry   => $interface
            );
        }
    }
}

sub _getMacvlanNetworks {
    my (%params) = (
        command => 'docker network ls --filter driver=macvlan -q',
        @_
    );

    return getAllLines(%params);
}

sub _getInterfaces {
    my (%params) = @_;

    my $lines = getAllLines(
        command => "docker network inspect $params{networkId}",
        %params
    ) or return;

    my @interfaces;

    my $data = decode_json $lines;

    foreach my $record (@$data) {
        while (my ($k, $container) = each %{$record->{Containers}}) {
            my $interface = {
                DESCRIPTION => $record->{Name} . "@" . $container->{Name},
                MACADDR     => $container->{MacAddress},
                STATUS      => 'Up',
                TYPE        => 'ethernet',
                VIRTUALDEV  => 1
            };
            if ($container->{IPv4Address} =~ /^($ip_address_pattern)\/(\d+)$/) {
                $interface->{IPADDRESS} = $1;
                $interface->{IPMASK} = getNetworkMask($2);
            }
            if ($container->{IPv6Address} =~ /^(\S+)\/(\d+)$/) {
                $interface->{IPADDRESS6} = $1;
                $interface->{IPMASK6} = getNetworkMaskIPv6($2);
            }
            push @interfaces, $interface;
        }
    }

    return @interfaces;
}

1;
