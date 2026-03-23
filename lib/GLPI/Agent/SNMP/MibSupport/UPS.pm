package GLPI::Agent::SNMP::MibSupport::UPS;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    apc => '.1.3.6.1.4.1.318' ;

# See RIELLO-MIB

use constant    riello => '.1.3.6.1.4.1.5491';

# See RIELLOUPS-MIB

use constant    rupsIdentManufacturer       => riello . '.10.1.1.1.0';
use constant    rupsIdentModel              => riello . '.10.1.1.2.0';
use constant    rupsIdentUPSSoftwareVersion => riello . '.10.1.1.3.0';

# See PowerNet-MIB

use constant    upsAdvIdentSerialNumber => apc . '.1.1.1.1.2.3.0';
use constant    sPDUIdentFirmwareRev    => apc . '.1.1.4.1.2.0';
use constant    sPDUIdentModelNumber    => apc . '.1.1.4.1.4.0';
use constant    sPDUIdentSerialNumber   => apc . '.1.1.4.1.5.0';

# See UPS-MIB

use constant    upsMIB  => '.1.3.6.1.2.1.33' ;
use constant    upsIdentManufacturer        => upsMIB  .'.1.1.1.0' ;
use constant    upsIdentModel               => upsMIB  .'.1.1.2.0' ;
use constant    upsIdentUPSSoftwareVersion  => upsMIB  .'.1.1.3.0' ;

our $mibSupport = [
    {
        name        => "apc",
        sysobjectid => getRegexpOidMatch(apc)
    },
    {
        name        => "ups-mib",
        sysobjectid => getRegexpOidMatch(upsMIB)
    },
    {
        name        => "riello",
        sysobjectid => getRegexpOidMatch(riello)
    }
];

sub getModel {
    my ($self) = @_;

    if ($self->is("riello")) {
        my $model = getCanonicalString($self->get(rupsIdentModel));
        return $model unless empty($model);
    }

    return getCanonicalString($self->get(upsIdentModel) || $self->get(sPDUIdentModelNumber));
}

sub getSerial {
    my ($self) = @_;

    return $self->get(upsAdvIdentSerialNumber) || $self->get(sPDUIdentSerialNumber);
}

sub getFirmware {
    my ($self) = @_;

    if ($self->is("riello")) {
        my $firmware = getCanonicalString($self->get(rupsIdentUPSSoftwareVersion));
        return $firmware unless empty($firmware);
    }

    return getCanonicalString($self->get(upsIdentUPSSoftwareVersion) || $self->get(sPDUIdentFirmwareRev));
}

sub getManufacturer {
    my ($self) = @_;

    if ($self->is("riello")) {
        my $manufacturer = getCanonicalString($self->get(rupsIdentManufacturer));
        return $manufacturer unless empty($manufacturer);
    }

    return getCanonicalString($self->get(upsIdentManufacturer));
}

sub getType {
    # TODO remove when POWER is supported on server-side and replace by 'POWER'
    return 'NETWORKING';
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::UPS - Inventory module for APC modules

=head1 DESCRIPTION

The module enhances APC devices support.
