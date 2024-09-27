package GLPI::Agent::SNMP::MibSupport::Aerohive;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See AH-SMI-MIB
use constant aerohive   => '.1.3.6.1.4.1.26928';
use constant ahProduct  => aerohive . '.1';

# See AH-SYSTEM-MIB
use constant ahSystem   => ahProduct . '.2';
use constant ahSystemName       => ahSystem . '.1.0';
use constant ahSystemSerial     => ahSystem . '.5.0';
use constant ahDeviceMode       => ahSystem . '.6.0';
use constant ahHwVersion        => ahSystem . '.8.0';
use constant ahFirmwareVersion  => ahSystem . '.12.0';

our $mibSupport = [
    {
        name    => "aerohive",
        sysobjectid => getRegexpOidMatch(aerohive)
    }
];

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    my ($self) = @_;

    return 'Aerohive Networks';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(ahSystemSerial));
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(ahFirmwareVersion));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(ahDeviceMode));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $ahHwVersion = getCanonicalString($self->get(ahHwVersion));
    if ($ahHwVersion) {
        my $firmware = {
            NAME            => "Aerohive hardware",
            DESCRIPTION     => "Aerohive platform hardware version",
            TYPE            => "hardware",
            VERSION         => $ahHwVersion,
            MANUFACTURER    => "Aerohive Networks"
        };
        $device->addFirmware($firmware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Aerohive - Inventory module for Aerohive Networks

=head1 DESCRIPTION

This module enhances Aerohive Networks devices support.
