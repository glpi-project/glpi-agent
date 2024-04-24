package GLPI::Agent::SNMP::MibSupport::Dell;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# Constants extracted from Dell-Vendor-MIB
use constant enterprises    => '.1.3.6.1.4.1';
use constant dell           => enterprises . '.674';

use constant powerConnectVendorMIB  => dell . '.10895.3000';
use constant hardware               => powerConnectVendorMIB . '.1.2' ;
use constant productIdentification  => hardware . ".100" ;

use constant productIdentificationDisplayName   => productIdentification . ".1.0" ;
use constant productIdentificationVendor        => productIdentification . ".3.0" ;
use constant productIdentificationVersion       => productIdentification . ".4.0" ;
use constant productIdentificationSerialNumber  => productIdentification . ".8.1.2.1" ;
use constant productIdentificationAssetTag      => productIdentification . ".8.1.3.1" ;
use constant productIdentificationServiceTag    => productIdentification . ".8.1.4.1" ;

use English qw(-no_match_vars);
use UNIVERSAL::require;

our $mibSupport = [
    {
        name    => "dell-powerconnect",
        oid     => powerConnectVendorMIB
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(productIdentificationVersion));
}

sub getManufacturer {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{MANUFACTURER};

    return getCanonicalString($self->get(productIdentificationVendor)) || 'Dell';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(productIdentificationSerialNumber));
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{MODEL};

    return getCanonicalString($self->get(productIdentificationDisplayName));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $assettag = getCanonicalString($self->get(productIdentificationAssetTag));
    if (empty($assettag) || $assettag =~ /^none$/i) {
        my $servicetag = getCanonicalString($self->get(productIdentificationServiceTag));
        $device->{INFO}->{ASSETTAG} = $servicetag
            unless empty($servicetag) || $servicetag =~ /^none$/i;
    } else {
        $device->{INFO}->{ASSETTAG} = $assettag;
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Dell - Inventory module for Dell PowerConnect switches

=head1 DESCRIPTION

The module enhances support for Dell devices
