package GLPI::Agent::SNMP::MibSupport::Avocent;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# ACS8000-MIB
use constant    avocent => ".1.3.6.1.4.1.10418" ;

use constant    acsAppliance    => avocent . ".26.2.1";

use constant    acsHostName         => acsAppliance . ".1.0";
use constant    acsProductModel     => acsAppliance . ".2.0";
use constant    acsSerialNumber     => acsAppliance . ".4.0";
use constant    acsBootcodeVersion  => acsAppliance . ".6.0";
use constant    acsFirmwareVersion  => acsAppliance . ".7.0";

our $mibSupport = [
    {
        name        => "avocent",
        sysobjectid => getRegexpOidMatch(avocent)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(acsFirmwareVersion));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(acsProductModel));
}

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(acsHostName));
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(acsSerialNumber));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Handle bootcode version if found
    my $bootcodeVersion = getCanonicalString($self->get(acsBootcodeVersion));
    unless (empty($bootcodeVersion)) {
        my $model = $device->{MODEL} ? $device->{MODEL}." " : "";
        my $bootcodeFirmware = {
            NAME            => $model."bootcode",
            DESCRIPTION     => "bootcode firmware version",
            TYPE            => "device",
            VERSION         => $bootcodeVersion,
            MANUFACTURER    => "Avocent"
        };

        $device->addFirmware($bootcodeFirmware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Avocent - Inventory module for Avocent devices

=head1 DESCRIPTION

The module enhances support for Avocent devices
