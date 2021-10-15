package GLPI::Agent::SNMP::MibSupport::iLO;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# Constants extracted from Compaq cpqsm2.mib, as said in mib:
# Implementation of the cpqSm2Cntrl group is mandatory for all agents
# supporting the Remote Insight/Integrated Lights-Out MIB.
# All Compaq iLO sysobjectid starts with .1.3.6.1.4.1.232.9.4
use constant    compaq      => '.1.3.6.1.4.1.232' ;
use constant    cpqSm2Cntrl => compaq . '.9.2.2' ;
use constant    cpqSm2Nic   => compaq . '.9.2.5' ;

our $mibSupport = [
    {
        name        => "cpqsm2",
        sysobjectid => qr/^\.1\.3\.6\.1\.4\.1\.232\.9\.4/
    }
];

sub getFirmware {
    my ($self) = @_;

    return $self->get(cpqSm2Cntrl . '.2.0');
}

sub getFirmwareDate {
    my ($self) = @_;

    return $self->get(cpqSm2Cntrl . '.1.0');
}

sub getSerial {
    my ($self) = @_;

    return $self->get(cpqSm2Cntrl . '.15.0');
}

sub getMacAddress {
    my ($self) = @_;

    my $cpqSm2NicConfigEntry = $self->_cpqSm2NicConfigEntry();
    return unless ref($cpqSm2NicConfigEntry) eq 'ARRAY' && @{$cpqSm2NicConfigEntry};

    return $cpqSm2NicConfigEntry->[3];
}

sub getIp {
    my ($self) = @_;

    my $cpqSm2NicConfigEntry = $self->_cpqSm2NicConfigEntry();
    return unless ref($cpqSm2NicConfigEntry) eq 'ARRAY' && @{$cpqSm2NicConfigEntry};

    return $cpqSm2NicConfigEntry->[4];
}

# TODO: Report server GUID so it is possible to link iLO to related host
#sub _getServerGUID {
#    my ($self) = @_;
#
#    return $self->get(cpqSm2Cntrl . '.26.0');
#}

my $sm2seq;
# Handle cached cpqSm2NicConfigEntry sequence to limit walk during netinventory
sub _cpqSm2NicConfigEntry {
    my ($self) = @_;

    return $sm2seq ?
        $sm2seq : $sm2seq = $self->getSequence(cpqSm2Nic . '.1.1');
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $cpqSm2NicConfigEntry = $self->_cpqSm2NicConfigEntry();
    return unless ref($cpqSm2NicConfigEntry) eq 'ARRAY' && @{$cpqSm2NicConfigEntry};

    my @status = qw(- 2 1 2);

    my $port = {
        IFNUMBER        => 1,
        IFDESCR         => getCanonicalString($cpqSm2NicConfigEntry->[1]),
        MAC             => getCanonicalMacAddress($cpqSm2NicConfigEntry->[3]),
        IFSTATUS        => $status[getCanonicalConstant($cpqSm2NicConfigEntry->[6])] || '2',
        IFPORTDUPLEX    => getCanonicalConstant($cpqSm2NicConfigEntry->[7]),
        IFSPEED         => getCanonicalConstant($cpqSm2NicConfigEntry->[8]) * 1000,
        IFMTU           => getCanonicalConstant($cpqSm2NicConfigEntry->[11]),
        IPS             => {
            IP  => [ $cpqSm2NicConfigEntry->[4] ]
        }
    };

    $device->addPort( 1 => $port );
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::iLO - Inventory module for Digi modems and associated sim cards & firmwares

=head1 DESCRIPTION

The module adds SIMCARDS, MODEMS & FIRMWARES support for Digi devices
