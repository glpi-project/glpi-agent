package GLPI::Agent::SNMP::MibSupport::Zyxel;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    priority => 5;

# See ZYXEL-ES-SMI
use constant    zyxel => '.1.3.6.1.4.1.890' ;
use constant    products => zyxel . '.1';
use constant    enterpriseSolution => products . '.15';
use constant    esMgmt => enterpriseSolution . '.3';

# From ZYXEL-ES-COMMON
use constant    esSysInfo => esMgmt . '.1' ;
use constant    sysSwVersionString     => esSysInfo . '.6.0' ;
use constant    sysProductModel        => esSysInfo . '.11.0' ;
use constant    sysProductSerialNumber => esSysInfo . '.12.0' ;

our $mibSupport = [
    {
        name        => "zyxel",
        sysobjectid => getRegexpOidMatch(enterpriseSolution)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(sysSwVersionString));
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(sysProductSerialNumber));
}

sub getManufacturer {
    my ($self) = @_;

    return "Zyxel";
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(sysProductModel));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Zyxel - Inventory module for Zyxel devices

=head1 DESCRIPTION

The module enhances Zyxel devices support.
