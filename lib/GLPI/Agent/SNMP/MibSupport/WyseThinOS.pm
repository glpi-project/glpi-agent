package GLPI::Agent::SNMP::MibSupport::WyseThinOS;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    enterprises => '.1.3.6.1.4.1' ;

# WYSE-MIB DEFINITIONS
use constant    wyse            => enterprises . '.714' ;
use constant    ThinClient      => wyse . '.1.2' ;
use constant    SerialNumber    => ThinClient . '.6.2.1.0' ;

our $mibSupport = [
    {
        name        => "wyse-thinos",
        sysobjectid => getRegexpOidMatch(ThinClient)
    }
];

sub getType {
    return 'NETWORKING';
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my ($model) = $device->{DESCRIPTION} =~ /^(\S+)/
        or return;

    return "Wyse $model";
}

sub getManufacturer {
    return "Dell";
}

sub getSerial {
    my ($self) = @_;

    return $self->get(SerialNumber);
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my ($version) = $device->{DESCRIPTION} =~ /^\S+\s+(.*)$/
        or return;

    $device->addFirmware({
        NAME            => "ThinOS",
        DESCRIPTION     => "Dell Wyse ThinOS",
        TYPE            => "system",
        VERSION         => $version,
        MANUFACTURER    => "Dell"
    });
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::WyseThinOS - Inventory module for Dell ThinClient

=head1 DESCRIPTION

The module tries to enhance the Dell Wyse thinclients support.
