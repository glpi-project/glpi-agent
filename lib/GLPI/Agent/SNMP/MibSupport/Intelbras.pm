package GLPI::Agent::SNMP::MibSupport::Intelbras;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See DAHUA-SNMP-MIB
use constant dahua  => '.1.3.6.1.4.1.1004849';

use constant systemInfo => dahua . '.2.1';

use constant softwareRevision   => systemInfo . '.1.1.0';
use constant hardwareRevision   => systemInfo . '.1.2.0';
use constant serialNumber       => systemInfo . '.2.4.0';
use constant systemVersion      => systemInfo . '.2.5.0';
use constant deviceType         => systemInfo . '.2.6.0';

our $mibSupport = [
    {
        name    => "intelbras",
        oid     => systemInfo
    }
];

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    my ($self) = @_;

    return 'Intelbras';
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

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $hardwareRevision = getCanonicalString($self->get(hardwareRevision));
    if ($hardwareRevision) {
        my $firmware = {
            NAME            => "Intelbras hardware",
            DESCRIPTION     => "Hardware version",
            TYPE            => "hardware",
            VERSION         => $hardwareRevision,
            MANUFACTURER    => "Intelbras"
        };
        $device->addFirmware($firmware);
    }

    my $systemVersion = getCanonicalString($self->get(systemVersion));
    if ($systemVersion) {
        my $firmware = {
            NAME            => "Intelbras system",
            DESCRIPTION     => "System version",
            TYPE            => "system",
            VERSION         => $systemVersion,
            MANUFACTURER    => "Intelbras"
        };
        $device->addFirmware($firmware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Intelbras - Inventory module for Intelbras

=head1 DESCRIPTION

This module enhances Intelbras products support.
