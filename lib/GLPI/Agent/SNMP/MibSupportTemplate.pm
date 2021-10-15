package GLPI::Agent::SNMP::MibSupportTemplate;

use strict;
use warnings;

#use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

#use GLPI::Agent::Tools::SNMP;

# Default priority to permit to priorize a MibSupport module other another
# A lower priority means use it before the other
use constant    priority    => 10;

# define here constants as defined in related mib
use constant    enterprises     => '.1.3.6.1.4.1' ;
#use constant   sectionOID      => enterprises . '.XYZ';
#use constant   valueOID        => oidSection . '.xyz.abc';
#use constant   mibOID          => oidSection . '.x.y.z';

our $mibSupport = [
    # Examples of mib support by sysobjectid matching
    #{
    #    name        => "mibName",
    #    sysobjectid => qr/^\.1\.3\.6\.1\.4\.1\.ENTREPRISE\.X\.Y/
    #},
    #{
    #    name        => "mibName",
    #    sysobjectid => getRegexpOidMatch(enterprises . '.ENTREPRISE.X.Y')
    #},
    # Example of mib support by checking snmp agent exposed mib support
    # via sysORID entries
    #{
    #    name    => "mibName",
    #    oid     => mibOID
    #}
];

sub new {
    my ($class, %params) = @_;

    return unless $params{device};

    my $self = {
        _device     => $params{device},
        _mibsupport => $params{mibsupport},
    };

    bless $self, $class;

    return $self;
}

sub device {
    my ($self) = @_;

    return $self->{_device};
}

sub support {
    my ($self) = @_;

    return $self->{_mibsupport};
}

sub get {
    my ($self, $oid) = @_;

    return $self->{_device} && $self->{_device}->get($oid);
}

sub walk {
    my ($self, $oid) = @_;

    return $self->{_device} && $self->{_device}->walk($oid);
}

sub getSequence {
    my ($self, $oid) = @_;

    return unless $self->{_device};

    my $walk = $self->{_device}->walk($oid);

    return unless $walk;

    return [
        map { $walk->{$_} }
        sort  { $a <=> $b }
        keys %$walk
    ];
}

sub getFirmware {
    #my ($self) = @_;

    #return $self->get(sectionOID . '.X.A');
}

sub getFirmwareDate {
    #my ($self) = @_;

    #return $self->get(sectionOID . '.X.B');
}

sub getSerial {
    #my ($self) = @_;

    #return $self->get(sectionOID . '.X.C');
}

sub getMacAddress {
    #my ($self) = @_;

    #return $self->get(sectionOID . '.X.D');
}

sub getIp {
    #my ($self) = @_;

    #return $self->get(sectionOID . '.X.E');
}

sub getModel {
    #my ($self) = @_;

    #return $self->get(sectionOID . '.X.F');
}

sub getType {
    #my ($self) = @_;

    #return 'NETWORKING' if $self->get(sectionOID . '.X.G') eq 'XYZ';
}

sub getSnmpHostname {
    #my ($self) = @_;

    #return $self->get(sectionOID . '.X.H');
}

sub getManufacturer {
    #my ($self) = @_;

    #return $self->get(sectionOID . '.X.H');
}

sub getComponents {
    #my ($self) = @_;

    #return [];
}

sub run {
    #my ($self) = @_;

    #my $device = $self->device
    #    or return;

    #my $other_firmware = {
    #    NAME            => 'XXX Device',
    #    DESCRIPTION     => 'XXX ' . $self->get(sectionOID . '.X.D') .' device',
    #    TYPE            => 'Device type',
    #    VERSION         => $self->get(sectionOID . '.X.D'),
    #    MANUFACTURER    => 'XXX'
    #};
    #$device->addFirmware($other_firmware);
}

sub configure {
    # Use this API for module initialization
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupportTemplate - Parent/Template class for inventory module

=head1 DESCRIPTION

Base class used for Mib support
