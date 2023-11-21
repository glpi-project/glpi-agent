package GLPI::Agent::SNMP::MibSupport::Toshiba;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant toshibatec => '.1.3.6.1.4.1.1129';

use constant bcpGeneral         => toshibatec . '.1.2.1.1.1.1';
use constant bcpProductNumber   => bcpGeneral . '.1.0';
use constant bcpProductVersion  => bcpGeneral . '.2.0';


use constant bcpDeviceEntry         => toshibatec . '.1.2.1.1.1.2';
use constant bcpDeviceModel         => bcpDeviceEntry . '.1.0';
use constant bcpDeviceBootVersion   => bcpDeviceEntry . '.5.0';

our $mibSupport = [
    {
        name        => "toshiba",
        sysobjectid => getRegexpOidMatch(toshibatec)
    }
];

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(bcpProductNumber));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(bcpDeviceModel));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $version = getCanonicalString($self->get(bcpProductVersion));
    if ($version) {
        $version =~ s/^B/V/;
        my $firmware = {
            NAME            => "Toshiba firmware",
            DESCRIPTION     => "Toshiba printer firmware",
            TYPE            => "printer",
            VERSION         => $version,
            MANUFACTURER    => "Toshiba"
        };
        $device->addFirmware($firmware);
    }

    my $bootversion = getCanonicalString($self->get(bcpDeviceBootVersion));
    if ($bootversion) {
        my $firmware = {
            NAME            => "Toshiba boot software",
            DESCRIPTION     => "Boot software version",
            TYPE            => "printer",
            VERSION         => $bootversion,
            MANUFACTURER    => "Toshiba"
        };
        $device->addFirmware($firmware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Toshiba - Inventory module for Toshiba printers

=head1 DESCRIPTION

This module enhances Toshiba printers support.
