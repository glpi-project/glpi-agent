package FusionInventory::Agent::SNMP::MibSupport::Kyocera;

use strict;
use warnings;

use parent 'FusionInventory::Agent::SNMP::MibSupportTemplate';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::SNMP;

use constant kyocera    => '.1.3.6.1.4.1.1347';
use constant sysName    => kyocera . '.40.10.1.1.5.1';

use constant kyoceraPrinter => kyocera . '.41';

our $mibSupport = [
    {
        name        => "kyocera",
        sysobjectid => getRegexpOidMatch(kyoceraPrinter)
    }
];

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(sysName));
}

1;

__END__

=head1 NAME

FusionInventory::Agent::SNMP::MibSupport::Kyocera - Inventory module for Kyocera printers

=head1 DESCRIPTION

This module enhances Kyocera printers support.
