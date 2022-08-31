#
# OcsInventory agent - IPMI lan channel report
#
# Copyright (c) 2008 Jean Parpaillon <jean.parpaillon@kerlabs.com>
#
# The Intelligent Platform Management Interface (IPMI) specification
# defines a set of common interfaces to a computer system which system
# administrators can use to monitor system health and manage the
# system. The IPMI consists of a main controller called the Baseboard
# Management Controller (BMC) and other satellite controllers.
#
# The BMC can be fetched through client like OpenIPMI drivers or
# through the network. Though, the BMC hold a proper MAC address.
#
# This module reports the MAC address and, if any, the IP
# configuration of the BMC. This is reported as a standard NIC.
#
package GLPI::Agent::Task::Inventory::Generic::Ipmi::Lan;

use strict;
use warnings;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;

use constant    category    => "network";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @lines = getAllLines(
        logger => $logger,
        command => "ipmitool lan print",
    );
    return unless @lines;

    my $interface = {
        DESCRIPTION => 'bmc',
        TYPE        => 'ethernet',
        MANAGEMENT  => 1,
        STATUS      => 'Down',
    };

    foreach my $line (@lines) {
        if ($line =~ /^IP Address\s+:\s+($ip_address_pattern)/) {
            $interface->{IPADDRESS} = $1 unless $1 eq '0.0.0.0';
        }
        if ($line =~ /^Default Gateway IP\s+:\s+($ip_address_pattern)/) {
            $interface->{IPGATEWAY} = $1 unless $1 eq '0.0.0.0';
        }
        if ($line =~ /^Subnet Mask\s+:\s+($ip_address_pattern)/) {
            $interface->{IPMASK} = $1 unless $1 eq '0.0.0.0';
        }
        if ($line =~ /^MAC Address\s+:\s+($mac_address_pattern)/) {
            $interface->{MACADDR} = $1;
        }
    }

    $interface->{IPSUBNET} = getSubnetAddress(
        $interface->{IPADDRESS}, $interface->{IPMASK}
    );

    $interface->{STATUS} = 'Up' if $interface->{IPADDRESS};

    $inventory->addEntry(
        section => 'NETWORKS',
        entry   => $interface
    );
}

1;
