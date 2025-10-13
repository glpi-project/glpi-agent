package GLPI::Agent::SNMP::MibSupport::HitachiVantara;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant hitachi    => '.1.3.6.1.4.1.116';

use constant hitachiVslSysObjectID     => hitachi . '.3.11.4.1.1';

use constant raidExMibRaidListEntry => hitachi . '.5.11.4.1.1.5.1';
use constant raidlistSerialNumber   => raidExMibRaidListEntry . '.1';

our $mibSupport = [
    {
        name    => "hitachi-vantara",
        sysobjectid => getRegexpOidMatch(hitachiVslSysObjectID)
    }
];

sub _getPrivate {
    my ($self, $index) = @_;

    my $key = $self->{_deviceKey};

    unless ($key) {
        my $walk = $self->walk(raidlistSerialNumber);
        ($key) = sort keys(%{$walk});
        $self->{_deviceKey} = $key;
    }

    return $self->get(raidExMibRaidListEntry . $index . "." . $key);
}

sub getType {
    my ($self) = @_;

    return "STORAGE" if $self->getModel() =~ /^VSP/;
    return 'NETWORKING';
}

sub getManufacturer {
    my ($self) = @_;

    return 'Hitachi Vantara';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->_getPrivate(".1"));
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->_getPrivate(".3"));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->_getPrivate(".4"));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::HitachiVantara - Inventory module for Hitachi Vantara devices

=head1 DESCRIPTION

This module enhances Hitachi Vantara devices support.
