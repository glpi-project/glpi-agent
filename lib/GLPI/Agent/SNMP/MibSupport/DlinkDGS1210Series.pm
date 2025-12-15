package GLPI::Agent::SNMP::MibSupport::DlinkDGS1210Series;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# Constants extracted from D-Link MIBs
use constant enterprises    => '.1.3.6.1.4.1';
use constant d_link         => enterprises . '.171';
use constant dlink_products => d_link . '.10';
use constant dlink_mgmt     => d_link . '.11';

use constant dlink_DGS1210SeriesProd    => dlink_products . '.153';

use constant dlink_dgs_1210_Common  => dlink_mgmt . '.153.1000';

use constant companySystem      => dlink_dgs_1210_Common . ".1";

use constant sysSwitchName      => companySystem . ".1.0";
use constant sysHardwareVersion => companySystem . ".2.0";
use constant sysFirmwareVersion => companySystem . ".3.0";

use constant sysSerialNumber    => companySystem . ".33.1.0";

our $mibSupport = [
    {
        name    => "d-link-dgs1210-series",
        oid     => companySystem
    }
];

sub getType {
    return 'NETWORKING';
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(sysFirmwareVersion));
}

sub getManufacturer {
    return 'D-Link';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(sysSerialNumber));
}

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(sysSwitchName));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Handle hardware revision
    my $sysHardwareVersion = getCanonicalString($self->get(sysHardwareVersion));
    unless (empty($sysHardwareVersion)) {
        my $model = $device->{MODEL} ? $device->{MODEL}." " : "";
        my $sysHardware = {
            NAME            => $model."hardware",
            DESCRIPTION     => "hardware revision",
            TYPE            => "device",
            VERSION         => $sysHardwareVersion,
            MANUFACTURER    => "D-Link"
        };

        $device->addFirmware($sysHardware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::DlinkDGS1210Series - Inventory module for D-Link DGS1210 switches series

=head1 DESCRIPTION

The module enhances support for D-Link devices
