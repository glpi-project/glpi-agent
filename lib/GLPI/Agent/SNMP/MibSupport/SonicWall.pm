package GLPI::Agent::SNMP::MibSupport::SonicWall;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    mib2        => '.1.3.6.1.2.1' ;
use constant    enterprises => '.1.3.6.1.4.1' ;

use constant    sonicwall   => enterprises . '.8741' ;

use constant    snwlSys     => sonicwall . '.2.1.1';

use constant    snwlSysModel            => snwlSys . '.1.0';
use constant    snwlSysSerialNumber     => snwlSys . '.2.0';
use constant    snwlSysFirmwareVersion  => snwlSys . '.3.0';
use constant    snwlSysROMVersion       => snwlSys . '.4.0';

our $mibSupport = [
    {
        name        => "sonicwall",
        sysobjectid => getRegexpOidMatch(sonicwall)
    }
];

sub getModel {
    my ($self) = @_;

    return $self->get(snwlSysModel);
}

sub getSerial {
    my ($self) = @_;

    return $self->get(snwlSysSerialNumber);
}

sub getFirmware {
    my ($self) = @_;

    return $self->get(snwlSysROMVersion);
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $SystemVersion = getSanitizedString(hex2char($self->get(snwlSysFirmwareVersion)));
    if ($SystemVersion) {
        # Add system firmware
        $device->addFirmware({
            NAME            => getSanitizedString(hex2char($self->getModel())),
            DESCRIPTION     => "SonicOS firmware",
            TYPE            => "system",
            VERSION         => $SystemVersion,
            MANUFACTURER    => "SonicWall"
        });
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::SonicWall - Inventory module for SonicWall devices

=head1 DESCRIPTION

The module enhances SonicWall devices support.
