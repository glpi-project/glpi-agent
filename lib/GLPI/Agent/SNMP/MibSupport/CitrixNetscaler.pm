package GLPI::Agent::SNMP::MibSupport::CitrixNetscaler;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See NS-ROOT-MIB
use constant netScaler  => '.1.3.6.1.4.1.5951';

use constant sysIpAddress               => netScaler . '.4.1.1.2.0';
use constant sysHardwareSerialNumber    => netScaler . '.4.1.1.14.0';

our $mibSupport = [
    {
        name        => "citrix-netscaler",
        sysobjectid => getRegexpOidMatch(netScaler)
    }
];

sub getIp {
    my ($self) = @_;

    return $self->get(sysIpAddress);
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(sysHardwareSerialNumber));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::CitrixNetscaler - Inventory module for Citrix Netscaler

=head1 DESCRIPTION

This module enhances Citrix Netscaler support.
