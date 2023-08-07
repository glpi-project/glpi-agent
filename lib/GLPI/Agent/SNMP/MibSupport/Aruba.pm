package GLPI::Agent::SNMP::MibSupport::Aruba;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See Q-BRIDGE-MIB
use constant    dot1qTpFdbStatus => '.1.3.6.1.2.1.17.7.1.2.2.1.3';

# See ARUBA-MIB
use constant    aruba   => '.1.3.6.1.4.1.14823' ;

# See AI-AP-MIB
use constant    aiMIB   => aruba . '.2.3.3.1' ;

use constant    aiVirtualControllerVersion  => aiMIB . '.1.4.0';
use constant    aiAPSerialNum               => aiMIB . '.2.1.1.4';
use constant    aiAPModelName               => aiMIB . '.2.1.1.6';

our $mibSupport = [
    {
        name        => "aruba",
        sysobjectid => getRegexpOidMatch(aruba)
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(aiVirtualControllerVersion));
}

sub _this {
    my ($self) = @_;

    unless ($self->{_this}) {
        # Find reference to our device
        my $dot1qTpFdbStatus = $self->walk(dot1qTpFdbStatus);
        if ($dot1qTpFdbStatus) {
            my ($subkey) = first {
                $dot1qTpFdbStatus->{$_} eq '4' } keys(%{$dot1qTpFdbStatus});
            my ($extracted) = $subkey =~ /^\d+\.(.*)$/;
            $self->{_this} = $extracted if $extracted;
        }
    }

    return $self->{_this};
}

sub getSerial {
    my ($self) = @_;

    my $this = $self->_this
        or return;

    return getCanonicalString($self->get(aiAPSerialNum.'.'.$this));
}

sub getModel {
    my ($self) = @_;

    my $this = $self->_this;
    if ($this) {
        my $model = getCanonicalString($self->get(aiAPModelName.'.'.$this));
        return "AP $model" if $model;
    }

    my $device = $self->device
        or return;

    my $model;

    # Extract model from device description for ArubaOS based systems
    ( $model ) = $device->{DESCRIPTION} =~ /^ArubaOS\s+\(MODEL:\s*(.*)\)/
        if $device->{DESCRIPTION};

    return unless $model;

    return "AP $model";
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Aruba - Inventory module for Aruba AP

=head1 DESCRIPTION

The module enhances Aruba wifi access point devices support.
