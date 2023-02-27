package GLPI::Agent::SNMP::MibSupport::Canon;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See CANON-MIB & PRINTER-PORT-MONITOR-MIB

use constant enterprises    => '.1.3.6.1.4.1';
use constant canon          => enterprises . '.1602';
use constant ppmMIB         => enterprises . '.2699.1.2';

use constant canProductInfo => canon . '.1.1.1';
use constant canPdInfoProductName       => canProductInfo . '.1.0';
use constant canPdInfoProductVersion    => canProductInfo . '.4.0';

use constant canServInfoSerialNumberTable => canon . '.1.2.1.8';
use constant canServInfoSerialNumberDeviceNumber    => canServInfoSerialNumberTable . '.1.3.1.1';

use constant ppmPrinter     => ppmMIB . '.1.2';
use constant ppmPrinterName => ppmPrinter . '.1.1.2.1';

our $mibSupport = [
    {
        name        => "canon",
        sysobjectid => qr/^\.1\.3\.6\.1\.4\.1\.1602\.4\./
    }
];

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(canServInfoSerialNumberDeviceNumber));
}

sub getFirmware {
    my ($self) = @_;

    return $self->get(canPdInfoProductVersion);
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{MODEL};

    return getCanonicalString($self->get(canPdInfoProductName) || $self->get(ppmPrinterName));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Canon - Inventory module for Canon

=head1 DESCRIPTION

This module enhances Canon printers support.
