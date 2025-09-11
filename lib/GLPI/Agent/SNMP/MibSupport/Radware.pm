package GLPI::Agent::SNMP::MibSupport::Radware;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    enterprises => '.1.3.6.1.4.1' ;

# ALTEON-ROOT-MIB
use constant    alteon  => enterprises . '.1872';
use constant    awsswitch   => alteon . '.2.5';

# ALTEON-CHEETAH-SWITCH-MIB
use constant    agent   => awsswitch . '.1';

use constant    agentConfig => agent . '.1';
use constant    agentInfo   => agent . '.3';

use constant    agSystem    => agentConfig . '.1';
use constant    agMgmt      => agentConfig . '.9';

use constant    hardware    => agentInfo . '.1';

use constant    agPlatformIdentifier    => agSystem . ".77.0";

use constant    agMgmtCurCfgIpAddr      => agMgmt . ".1.0";

use constant    hwMainBoardNumber       => hardware . '.6.0';
use constant    hwMainBoardRevision     => hardware . '.7.0';
use constant    hwMACAddress            => hardware . '.13.0';
use constant    hwSerialNumber          => hardware . '.18.0';
use constant    hwPLDFirmwareVersion    => hardware . '.21.0';
use constant    hwVersion               => hardware . '.30.0';

our $mibSupport = [
    {
        name        => "alteon-radware",
        sysobjectid => getRegexpOidMatch(alteon)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(hwPLDFirmwareVersion));
}

sub getIp {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{IPS};

    my $ip = getCanonicalString($self->get(agMgmtCurCfgIpAddr))
        or return;

    return $ip;
}

sub getMacAddress {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{MAC};

    return getCanonicalMacAddress($self->get(hwMACAddress));
}

sub getManufacturer {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{MANUFACTURER};

    return 'Radware';
}

sub getModel {
    my ($self) = @_;

    my $model = getCanonicalString($self->get(agPlatformIdentifier))
        or return;

    return "Alteon $model";
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(hwSerialNumber));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $mbnum = getCanonicalString($self->get(hwMainBoardNumber));
    my $mbrev = getCanonicalString($self->get(hwMainBoardRevision));
    if ($mbnum && $mbrev) {
        my $firmware = {
            NAME            => "$device->{MODEL} $mbnum mainboard",
            DESCRIPTION     => "$device->{MODEL} $mbnum mainboard revision",
            TYPE            => "mainboard",
            VERSION         => $mbrev,
            MANUFACTURER    => "Radware"
        };
        $device->addFirmware($firmware);
    }

    my $hwVersion = getCanonicalString($self->get(hwVersion));
    if ($hwVersion) {
        my $firmware = {
            NAME            => "$device->{MODEL} hardware",
            DESCRIPTION     => "$device->{MODEL} hardware revision",
            TYPE            => "device",
            VERSION         => $hwVersion,
            MANUFACTURER    => "Radware"
        };
        $device->addFirmware($firmware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Radware - Inventory module for Radware devices

=head1 DESCRIPTION

The module enhances Radware devices support.
