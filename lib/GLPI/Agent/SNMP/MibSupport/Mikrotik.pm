package GLPI::Agent::SNMP::MibSupport::Mikrotik;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See MIKROTIK-MIB
use constant    mikrotikExperimentalModule  => '.1.3.6.1.4.1.14988.1' ;
use constant    mtxrSystem => mikrotikExperimentalModule  .'.1.7' ;

use constant    mtxrSerialNumber    => mtxrSystem . '.3.0' ;
use constant    mtxrFirmwareVersion => mtxrSystem . '.4.0' ;

our $mibSupport = [
    {
        name        => "mikrotik",
        sysobjectid => getRegexpOidMatch(mikrotikExperimentalModule)
    }
];

sub getFirmware {
    my ($self) = @_;

    return $self->get(mtxrFirmwareVersion);
}

sub getSerial {
    my ($self) = @_;

    return $self->get(mtxrSerialNumber);
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $model;

    # Extract model from device description for RouterOS based systems
    ( $model ) = $device->{DESCRIPTION} =~ /^RouterOS\s+(.*)$/
        if $device->{DESCRIPTION};

    return $model;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Mikrotik - Inventory module for Mikrotik devices

=head1 DESCRIPTION

The module fixes Mikrotik SerialNumber & Firmware version support.
