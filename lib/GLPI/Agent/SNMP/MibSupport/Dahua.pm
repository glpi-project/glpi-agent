package GLPI::Agent::SNMP::MibSupport::Dahua;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    priority => 5;

# See DAHUA-SNMP-MIB
use constant dahua  => '.1.3.6.1.4.1.1004849';

use constant systemInfo => dahua . '.2.1';

use constant softwareRevision   => systemInfo . '.1.1.0';
use constant hardwareRevision   => systemInfo . '.1.2.0';
use constant serialNumber       => systemInfo . '.2.4.0';
use constant systemVersion      => systemInfo . '.2.5.0';
use constant deviceType         => systemInfo . '.2.6.0';
use constant machineName        => systemInfo . '.2.9.0';
use constant dahuaManufacturer  => systemInfo . '.2.11.0';

our $mibSupport = [
    {
        name    => "dahua",
        oid     => systemInfo
    }
];

sub getType {
    return 'NETWORKING';
}

# Few manufacturers use Dahua devices in white mark
my %manufacturerTag = qw(
    AC  Amcrest
    IB  Intelbras
    LR  Lorex
);

sub getManufacturer {
    my ($self) = @_;

    # First try to decode tag in firmware
    my $firmware = $self->getFirmware();
    if ($firmware && $firmware =~ /^\d+\.\d+\.00([A-Z]{2})\d+/) {
        return $manufacturerTag{$1} unless empty($manufacturerTag{$1});
        $self->debug("Unknown Dahua manufacturer tag: $1");
    }

    return getCanonicalString($self->get(dahuaManufacturer)) // 'Dahua';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(serialNumber));
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(softwareRevision));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(deviceType));
}

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(machineName));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $manufacturer = $device->{MANUFACTURER} // "Dahua";

    my $hardwareRevision = getCanonicalString($self->get(hardwareRevision));
    if ($hardwareRevision) {
        my $firmware = {
            NAME            => "$manufacturer hardware",
            DESCRIPTION     => "Hardware version",
            TYPE            => "hardware",
            VERSION         => $hardwareRevision,
            MANUFACTURER    => $manufacturer
        };
        $device->addFirmware($firmware);
    }

    my $systemVersion = getCanonicalString($self->get(systemVersion));
    if ($systemVersion) {
        my $firmware = {
            NAME            => "$manufacturer system",
            DESCRIPTION     => "System version",
            TYPE            => "system",
            VERSION         => $systemVersion,
            MANUFACTURER    => $manufacturer
        };
        $device->addFirmware($firmware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Dahua - Inventory module for Dahua

=head1 DESCRIPTION

This module enhances Dahua products support.
