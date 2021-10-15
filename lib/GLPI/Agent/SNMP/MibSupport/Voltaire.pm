package GLPI::Agent::SNMP::MibSupport::Voltaire;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    sysName     => '.1.3.6.1.2.1.1.5.0' ;
use constant    enterprises => '.1.3.6.1.4.1' ;

use constant    voltaire        => enterprises . '.5206' ;
use constant    serialnumber    => voltaire . '.3.29.1.3.1007.1';
use constant    version         => voltaire . '.3.1.0';

our $mibSupport = [
    {
        name        => "voltaire",
        sysobjectid => getRegexpOidMatch(voltaire)
    }
];

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    return 'Voltaire';
}

sub getModel {
    my ($self) = @_;

    my $sysName = $self->get(sysName)
        or return;

    my ($model) = $sysName =~ /^([^-]+)/;

    return $model;
}

sub getSerial {
    my ($self) = @_;

    return $self->get(serialnumber);
}

sub getFirmware {
    my ($self) = @_;

    return $self->get(version);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Voltaire - Inventory module for Voltaire devices

=head1 DESCRIPTION

The module enhances Voltaire devices support.
