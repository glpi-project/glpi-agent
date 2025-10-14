package GLPI::Agent::SNMP::MibSupport::Tiesse;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    sysDescr    => '.1.3.6.1.2.1.1.1.0';

use constant    entPhysicalDescr    => '.1.3.6.1.2.1.47.1.1.1.1.2.0';

use constant    tiesse  => ".1.3.6.1.4.1.4799" ;

use constant    privatePhysicalDescr  => tiesse . ".3.2.6023.0";

use constant    privateFirmware       => tiesse . ".200.1.0";
use constant    privateSerialNumber   => tiesse . ".200.2.0";

our $mibSupport = [
    {
        name        => "tiesse",
        sysobjectid => getRegexpOidMatch(tiesse)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(privateFirmware));
}

sub getModel {
    my ($self) = @_;

    my $model = getCanonicalString($self->get(privatePhysicalDescr) || $self->get(entPhysicalDescr));

    ($model) = $model =~ /^(?:\S+) (\S+\s\S+)/
        if $model && $model =~ /^Tiesse/i;

    return $model;
}

sub getManufacturer {
    return "Tiesse";
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(privateSerialNumber));
}

sub getType {
    return 'NETWORKING';
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Htek - Inventory module for Tiesse devices

=head1 DESCRIPTION

The module enhances support for Tiesse devices
