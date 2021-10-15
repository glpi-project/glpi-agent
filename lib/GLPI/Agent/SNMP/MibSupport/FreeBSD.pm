package GLPI::Agent::SNMP::MibSupport::FreeBSD;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# https://documentation.stormshield.eu/SNS/v3/fr/Content/User_Configuration_Manual_SNS_v3/SNMP_Agent/MIBS_and_traps_SNMP.htm
use constant    freebsd             => '.1.3.6.1.4.1.8072.3.2.8';
use constant    stormshield         => '.1.3.6.1.4.1.11256' ;
use constant    stormshield_model   => stormshield.'.1.0.1.0' ;
use constant    stormshield_fw_pri  => stormshield.'.1.0.2.0' ;
use constant    stormshield_serial  => stormshield.'.1.0.3.0' ;
use constant    stormshield_name    => stormshield.'.1.0.4.0' ;

our $mibSupport = [
    {
        name        => "FreeBSD",
        sysobjectid => getRegexpOidMatch(freebsd)
    }
];

sub _is_stormshield {
    my ($self) = @_;

    if (!defined $self->{STORMSHIELD}) {
        $self->{STORMSHIELD} = $self->get(stormshield_model) ? 1 : 0;
    }

    return $self->{STORMSHIELD};
}

sub getSerial {
    my ($self) = @_;

    return $self->get(stormshield_serial) if $self->_is_stormshield();
}


sub getFirmware {
    my ($self) = @_;

    return $self->get(stormshield_fw_pri) if $self->_is_stormshield();
}

sub getType {
    my ($self) = @_;

    return 'NETWORKING' if $self->_is_stormshield();
}

sub getModel {
    my ($self) = @_;

    return $self->get(stormshield_model) if $self->_is_stormshield();
}

sub getManufacturer {
    my ($self) = @_;

    return 'StormShield' if $self->_is_stormshield();
}

sub run {
    my ($self) = @_;

    if ($self->_is_stormshield()) {
        my $device = $self->device or return;

        my $name = $self->get(stormshield_name);
        $device->{INFO}->{NAME} = $name if $name;
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::FreeBSD - Inventory module for FreeBSD

=head1 DESCRIPTION

The module enhances FreeBSD devices support.
