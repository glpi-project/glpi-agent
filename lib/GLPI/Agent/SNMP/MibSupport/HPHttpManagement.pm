package GLPI::Agent::SNMP::MibSupport::HPHttpManagement;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See HP-ICF-OID
use constant    hpEtherSwitch   => '.1.3.6.1.4.1.11.2.3.7.11' ;

# See HP-HTTP-MG/SEMI
use constant    hpWebMgmt               => '.1.3.6.1.4.1.11.2.36' ;
use constant    hpHttpMgNetCitizen      => hpWebMgmt . '.1.1.2' ;
use constant    hpHttpMgVersion         => hpHttpMgNetCitizen . '.6.0' ;
use constant    hpHttpMgROMVersion      => hpHttpMgNetCitizen . '.8.0' ;
use constant    hpHttpMgSerialNumber    => hpHttpMgNetCitizen . '.9.0' ;

our $mibSupport = [
    {
        name        => "hp-etherswitch",
        sysobjectid => getRegexpOidMatch(hpEtherSwitch)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(hpHttpMgROMVersion));
}

sub getSerial {
    my ($self) = @_;

    return $self->get(hpHttpMgSerialNumber);
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $hpHttpMgVersion = $self->get(hpHttpMgVersion)
        or return;

    $device->addFirmware({
        NAME            => 'HP-HttpMg-Version',
        DESCRIPTION     => "HP Web Management Software version",
        TYPE            => "system",
        VERSION         => getCanonicalString($hpHttpMgVersion),
        MANUFACTURER    => "HP"
    });
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::HPHttpManagement - Inventory module for HP switchs with HTTP management

=head1 DESCRIPTION

The module enhances HP switchs devices support.
