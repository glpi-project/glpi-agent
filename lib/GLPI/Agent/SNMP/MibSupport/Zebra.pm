package GLPI::Agent::SNMP::MibSupport::Zebra;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See ESI-MIB

use constant    esi     => '.1.3.6.1.4.1.683' ;
use constant    model2  => esi . '.6.2.3.2.1.15.1' ;
use constant    serial  => esi . '.1.5.0' ;
use constant    fw2     => esi . '.1.9.0' ;

# See ZEBRA-MIB

use constant    zebra           => '.1.3.6.1.4.1.10642' ;
use constant    zbrGeneralInfo  => zebra . '.1' ;

use constant    zbrGeneralModel             => zbrGeneralInfo . '.1' ;
use constant    zbrGeneralFirmwareVersion   => zbrGeneralInfo . '.2.0' ;
use constant    zbrGeneralName              => zbrGeneralInfo . '.4.0' ;
use constant    zbrGeneralUniqueId          => zbrGeneralInfo . '.9.0' ;
use constant    zbrGeneralCompanyName       => zbrGeneralInfo . '.11.0' ;
use constant    zbrGeneralLINKOSVersion     => zbrGeneralInfo . '.18.0' ;

# See ZEBRA-QL-MIB

use constant    model1  => zbrGeneralModel . '.0' ;

use constant    zql_zebra_ql    => zebra . '.200' ;
use constant    model3  => zql_zebra_ql . '.19.7.0' ;
use constant    serial3 => zql_zebra_ql . '.19.5.0' ;

our $mibSupport = [
    {
        name        => "zebra-printer",
        sysobjectid => getRegexpOidMatch(esi)
    },
    {
        name        => "zebra-printer-zt",
        sysobjectid => getRegexpOidMatch(zbrGeneralModel)
    }
];

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(zbrGeneralName));
}

sub getManufacturer {
    my ($self) = @_;

    return getCanonicalString($self->get(zbrGeneralCompanyName)) || 'Zebra Technologies';
}

sub getSerial {
    my ($self) = @_;

    # serial3 is more accurate than serial on GK420 & ZE500
    return getCanonicalString($self->get(zbrGeneralUniqueId)) || hex2char($self->get(serial3) || $self->get(serial));
}

sub getModel {
    my ($self) = @_;

    return hex2char($self->get(model1) || $self->get(model2) || $self->get(model3));
}

sub getFirmware {
    my ($self) = @_;

    return hex2char($self->get(zbrGeneralFirmwareVersion) || $self->get(fw2));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $manufacturer = $self->getManufacturer()
        or return;

    my $linkos_version = $self->get(zbrGeneralLINKOSVersion);
    unless (empty($linkos_version)) {
        $device->addFirmware({
            NAME            => "$manufacturer LinkOS",
            DESCRIPTION     => "$manufacturer LinkOS firmware",
            TYPE            => "system",
            VERSION         => getCanonicalString($linkos_version),
            MANUFACTURER    => $manufacturer
        });
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Zebra - Inventory module for Zebra Printers

=head1 DESCRIPTION

The module enhances Zebra printers devices support.
