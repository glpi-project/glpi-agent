package GLPI::Agent::SNMP::MibSupport::Ruckus;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    enterprises => '.1.3.6.1.4.1' ;

# RUCKUS-ROOT-MIB
use constant    ruckusRootMIB               => enterprises . '.25053' ;
use constant    ruckusProducts              => ruckusRootMIB . '.3';
use constant    ruckusCommonHwInfoModule    => ruckusRootMIB . '.1.1.2';
use constant    ruckusCommonSwInfoModule    => ruckusRootMIB . '.1.1.3';

# RUCKUS-HWINFO-MIB
use constant    ruckusHwInfo                => ruckusCommonHwInfoModule . '.1.1.1';
use constant    ruckusHwInfoModelNumber     => ruckusHwInfo . '.1.0';
use constant    ruckusHwInfoSerialNumber    => ruckusHwInfo . '.2.0';

# RUCKUS-SWINFO-MIB
use constant    ruckusSwInfo                => ruckusCommonSwInfoModule . '.1.1.1';
use constant    ruckusSwRevision            => ruckusSwInfo . '.1.1.3.1';

our $mibSupport = [
    {
        name        => "ruckus",
        sysobjectid => getRegexpOidMatch(ruckusProducts)
    }
];

sub getModel {
    my ($self) = @_;

    return $self->get(ruckusHwInfoModelNumber);
}

sub getSerial {
    my ($self) = @_;

    return $self->get(ruckusHwInfoSerialNumber);
}

sub getFirmware {
    my ($self) = @_;

    return $self->get(ruckusSwRevision);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Ruckus - Inventory module for Ruckus devices

=head1 DESCRIPTION

The module enhances Ruckus devices support.
