package GLPI::Agent::SNMP::MibSupport::CiscoMeraki;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant sysDescr   => '.1.3.6.1.2.1.1.1.0';

# See MERAKI-CLOUD-CONTROLLER-MIB
use constant    meraki  => '.1.3.6.1.4.1.29671';
use constant    merakiProducts  => meraki . '.2';

our $mibSupport = [
    {
        name        => "cisco-meraki",
        sysobjectid => getRegexpOidMatch(merakiProducts)
    }
];

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    return 'Cisco Meraki';
}

sub getModel {
    my ($self) = @_;

    my $sysDescr = getCanonicalString($self->get(sysDescr));
    my ($model) = $sysDescr =~ /^Meraki\s+(\S+)/i;
    return $model unless empty($model);

    $sysDescr =~ s/, Modular Uplinks$//;

    return $sysDescr;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::CiscoMeraki - Inventory module to enhance Cisco Meraki devices support.

=head1 DESCRIPTION

The module enhances Cisco Meraki support.
