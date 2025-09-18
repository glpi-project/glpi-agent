package GLPI::Agent::SNMP::MibSupport::FoxGate;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant sysDescr   => '.1.3.6.1.2.1.1.1.0';

# FoxGate-MIB
use constant    FoxGate => ".1.3.6.1.4.1.6339" ;

use constant    os  => FoxGate . ".100";

use constant    sysHardwareVersion  => os . ".1.2.0";
use constant    sysSoftwareVersion  => os . ".1.3.0";

use constant    ntpEntSoftwareName  => os . ".25.1.1.1.0";

our $mibSupport = [
    {
        name        => "foxgate",
        sysobjectid => getRegexpOidMatch(FoxGate)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(sysSoftwareVersion));
}

sub getModel {
    my ($self) = @_;

    my $model = getCanonicalString($self->get(ntpEntSoftwareName));
    if (empty($model)) {
        my $sysDescr = getCanonicalString($self->get(sysDescr));
        my ($device) = split("\n", $sysDescr);
        ($model) = $device =~ /^(\S+) Device,/
            if $device;
    }
    return $model;
}

sub getManufacturer {
    return "FoxGate";
}

sub getSerial {
    my ($self) = @_;

    my $serial;

    my $sysDescr = getCanonicalString($self->get(sysDescr));
    my @lines = split("\n", $sysDescr);
    my $serialline = first { /^\s*Device serial number/ } @lines;
    ($serial) = $serialline =~ /^\s*Device serial number\s+(\S+)$/
        if $serialline;
    return $serial;
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $sysDescr = getCanonicalString($self->get(sysDescr));
    my @lines = split("\n", $sysDescr);
    my $model = $self->getModel();

    my $bootrom = first { /^\s*BootRom Version/ } @lines;
    if ($bootrom) {
        my ($version) = $bootrom =~ /^\s*BootRom Version\s+(\S+)$/;
        my $bootromFirmware = {
            NAME            => "$model bootrom",
            DESCRIPTION     => "bootrom version",
            TYPE            => "device",
            VERSION         => $version,
            MANUFACTURER    => "FoxGate"
        };
        $device->addFirmware($bootromFirmware);
    }

    my $hardware = first { /^\s*HardWare Version/ } @lines;
    if ($hardware) {
        my ($version) = $hardware =~ /^\s*HardWare Version\s+(\S+)$/;
        my $bootromFirmware = {
            NAME            => "$model hardware",
            DESCRIPTION     => "hardware version",
            TYPE            => "device",
            VERSION         => $version,
            MANUFACTURER    => "FoxGate"
        };
        $device->addFirmware($bootromFirmware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Htek - Inventory module for FoxGate devices

=head1 DESCRIPTION

The module enhances support for FoxGate devices
