package GLPI::Agent::SNMP::MibSupport::Cisco;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    priority => 5;

# See ENTITY-MIB
use constant    entPhysicalModelName    => '.1.3.6.1.2.1.47.1.1.1.1.13';

# See CISCO-SMI
use constant    cisco       => '.1.3.6.1.4.1.9';
use constant    cisco_local => cisco . '.2';

# See OLD-CISCO-MEMORY-MIB
use constant    hostName    => cisco_local . '.1.3.0' ;

our $mibSupport = [
    {
        name        => "cisco",
        sysobjectid => getRegexpOidMatch(cisco)
    }
];

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return getCanonicalString($device->{snmp}->get_first(entPhysicalModelName));
}

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(hostName));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Cisco - Inventory module to enhance Cisco devices support.

=head1 DESCRIPTION

The module enhances Cisco support.
