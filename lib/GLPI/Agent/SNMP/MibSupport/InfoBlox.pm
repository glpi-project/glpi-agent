package GLPI::Agent::SNMP::MibSupport::InfoBlox;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See IB-SMI-MIB

use constant enterprises    => '.1.3.6.1.4.1';
use constant infoblox       => enterprises . '.7779';
use constant ibPlatformOne  => infoblox . '.3.1.1.2';

# See IB-PLATFORMONE-MIB

use constant ibPlatformModule   => ibPlatformOne . '.1';

use constant ibHardwareType     => ibPlatformModule . '.4.0';
use constant ibSerialNumber     => ibPlatformModule . '.6.0';
use constant ibNiosVersion      => ibPlatformModule . '.7.0';

our $mibSupport = [
    {
        name        => "infoblox",
        sysobjectid => getRegexpOidMatch(infoblox)
    }
];

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(ibSerialNumber));
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(ibNiosVersion));
}

sub getManufacturer {
    my ($self) = @_;

    return 'InfoBlox';
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(ibHardwareType));
}

sub getType {
    return 'NETWORKING';
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::InfoBlox - Inventory module for InfoBlox

=head1 DESCRIPTION

This module enhances InfoBlox devices support.
