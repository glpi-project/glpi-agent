package GLPI::Agent::SNMP::MibSupport::Bachmann;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# NETTRACK-E3METER-SNMP-MIB
use constant    nettrack    => '.1.3.6.1.4.1.21695' ;

use constant    public      => nettrack . '.1' ;

use constant    e3Ipm       => public . '.10.7' ;

use constant    e3IpmInfoSerial     => e3Ipm . '.1.1';
use constant    e3IpmInfoHWVersion  => e3Ipm . '.1.3';
use constant    e3IpmInfoFWVersion  => e3Ipm . '.1.4';

our $mibSupport = [
    {
        name        => "bachmann-pdu",
        sysobjectid => getRegexpOidMatch(public)
    }
];

sub getType {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # From GLPI 12.0.0, this device can be reported as PDU
    my $glpi_version = $device->{glpi} ? glpiVersion($device->{glpi}) : 0;
    return $glpi_version && $glpi_version >= glpiVersion('12.0.0') ?
        "PDU" : "NETWORKING";
}

sub getManufacturer {
    my ($self) = @_;

    return 'Bachmann';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(e3IpmInfoSerial));
}

sub getFirmware {
    my ($self) = @_;

    my $fwrev = $self->get(e3IpmInfoFWVersion)
        or return;
    return unless isInteger($fwrev);

    $fwrev = int($fwrev);
    my $major = int($fwrev/256);
    my $minor = int($fwrev%256);

    return "$major.$minor";
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Handle hardware revision if found
    my $hwversion = $self->get(e3IpmInfoHWVersion);
    unless (empty($hwversion) || !isInteger($hwversion)) {
        my $hwRevision = {
            NAME            => "Hardware version",
            DESCRIPTION     => "Pdu hardware revision",
            TYPE            => "hardware",
            VERSION         => $hwversion,
            MANUFACTURER    => "Bachmann"
        };

        $device->addFirmware($hwRevision);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Bachmann - Inventory module for Bachmann Pdu devices

=head1 DESCRIPTION

The module enhances Bachmann Pdu devices support.
