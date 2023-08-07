package GLPI::Agent::SNMP::MibSupport::CheckPoint;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant checkpoint => '.1.3.6.1.4.1.2620';

use constant svn        => checkpoint . '.1.6';

use constant svnProdName        => svn . '.1.0';
use constant svnProdVerMajor    => svn . '.2.0';
use constant svnProdVerMinor    => svn . '.3.0';
use constant svnInfo            => svn . '.4';
use constant svnOSInfo          => svn . '.5';
use constant svnApplianceInfo   => svn . '.16';

use constant svnVersion         => svnInfo . '.1.0';
use constant svnBuild           => svnInfo . '.2.0';

use constant osName             => svnOSInfo . '.1.0';
use constant osMajorVer         => svnOSInfo . '.2.0';
use constant osMinorVer         => svnOSInfo . '.3.0';

use constant svnApplianceSerialNumber   => svnApplianceInfo . '.3.0';
use constant svnApplianceModel          => svnApplianceInfo . '.7.0';
use constant svnApplianceManufacturer   => svnApplianceInfo . '.9.0';

our $mibSupport = [
    {
        name        => "CheckPoint",
        sysobjectid => getRegexpOidMatch(checkpoint)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(svnVersion).' (build '.$self->get(svnBuild).')');
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(svnApplianceSerialNumber));
}

sub getManufacturer {
    my ($self) = @_;

    return getCanonicalString($self->get(svnApplianceManufacturer));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(svnApplianceModel));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $manufacturer = $self->getManufacturer()
        or return;

    my $svnProdVerMajor = $self->get(svnProdVerMajor);
    if (defined($svnProdVerMajor)) {
        $device->addFirmware({
            NAME            => getCanonicalString($self->get(svnProdName)),
            DESCRIPTION     => "$manufacturer SVN version",
            TYPE            => "system",
            VERSION         => getCanonicalString($svnProdVerMajor).'.'.getCanonicalString($self->get(svnProdVerMinor)),
            MANUFACTURER    => $manufacturer
        });
    }

    my $osMajorVer = $self->get(osMajorVer);
    if (defined($osMajorVer)) {
        $device->addFirmware({
            NAME            => getCanonicalString($self->get(osName)),
            DESCRIPTION     => "$manufacturer OS version",
            TYPE            => "system",
            VERSION         => getCanonicalString($osMajorVer).'.'.getCanonicalString($self->get(osMinorVer)),
            MANUFACTURER    => $manufacturer
        });
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::CheckPoint - Inventory module for CheckPoint appliance

=head1 DESCRIPTION

This module enhances CheckPoint appliances support.
