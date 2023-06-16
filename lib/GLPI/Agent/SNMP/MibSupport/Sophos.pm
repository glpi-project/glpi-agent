package GLPI::Agent::SNMP::MibSupport::Sophos;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See SFOS-FIREWALL-MIB

use constant sophosMIB          => '.1.3.6.1.4.1.2604';
use constant sfosXGMIB          => sophosMIB . '.5';
use constant sfosXGDeviceInfo   => sfosXGMIB . '.1.1';

use constant sfosDeviceName         => sfosXGDeviceInfo . '.1.0';
use constant sfosDeviceType         => sfosXGDeviceInfo . '.2.0';
use constant sfosDeviceFWVersion    => sfosXGDeviceInfo . '.3.0';
use constant sfosWebcatVersion      => sfosXGDeviceInfo . '.5.0';
use constant sfosIPSVersion         => sfosXGDeviceInfo . '.6.0';

our $mibSupport = [
    {
        name        => "sophos",
        sysobjectid => sfosXGMIB
    }
];

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(sfosDeviceType));
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(sfosDeviceFWVersion));
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(sfosDeviceName));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $webcat = getCanonicalString($self->get(sfosWebcatVersion));
    if ($webcat && $webcat !~ /Not available/i) {
        # Add webcat firmware
        my $webcatFirmware = {
            NAME            => "webcat",
            DESCRIPTION     => "Integrated webcat version",
            TYPE            => "software",
            VERSION         => $webcat,
            MANUFACTURER    => "Sophos"
        };

        $device->addFirmware($webcatFirmware);
    }

    my $snort = getCanonicalString($self->get(sfosIPSVersion));
    if ($snort && $snort !~ /Not available/i) {
        # Add snort firmware
        my $snortFirmware = {
            NAME            => "snort",
            DESCRIPTION     => "Integrated snort version",
            TYPE            => "software",
            VERSION         => $snort,
            MANUFACTURER    => "Sophos"
        };

        $device->addFirmware($snortFirmware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Sophos - Inventory module for Sophos UTM

=head1 DESCRIPTION

This module enhances Sophos devices support.
