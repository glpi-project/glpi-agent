package GLPI::Agent::SNMP::MibSupport::Telco;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See PRVT-VENDORDEF-MIB
use constant privateVendorOID   => '.1.3.6.1.4.1.738';

# See PRVT-SWITCH-MIB
use constant prvt_products  => privateVendorOID . '.1';
use constant switch         => prvt_products . '.5';
use constant prvtSwitchMib  => switch . '.100';
use constant sysSerialNumber    => prvtSwitchMib . '.1.3.1.0';
use constant sysSwitchModel     => prvtSwitchMib . '.1.3.2.0';
use constant sysHwRevision      => prvtSwitchMib . '.1.3.6.0';

our $mibSupport = [
    {
        name        => "telco-switch",
        oid         => switch
    }
];

sub getType {
    return 'NETWORKING';
}

sub getFirmware{
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless $device->{DESCRIPTION} && $device->{DESCRIPTION} =~ /software version (\S+)/;
    return $1;
}

sub getManufacturer {
    return 'Telco Systems';
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(sysSwitchModel));
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(sysSerialNumber));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Handle hardware revision
    my $sysHwRevision = getCanonicalString($self->get(sysHwRevision));
    unless (empty($sysHwRevision)) {
        my $model = $device->{MODEL} ? $device->{MODEL}." " : "";
        my $sysHardware = {
            NAME            => $model."hardware",
            DESCRIPTION     => $model."hardware revision",
            TYPE            => "device",
            VERSION         => $sysHwRevision,
            MANUFACTURER    => "Telco Systems"
        };

        $device->addFirmware($sysHardware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Telco - Inventory module for Telco devices

=head1 DESCRIPTION

The module enhances support for Telco devices
