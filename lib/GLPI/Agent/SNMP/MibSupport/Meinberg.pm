package GLPI::Agent::SNMP::MibSupport::Meinberg;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant priority => 20;

use constant sysdescr       => '.1.3.6.1.2.1.1.1.0';

# See MBG-SNMP-ROOT-MIB
use constant mbgSnmpRoot    => '.1.3.6.1.4.1.5597';

# See MBG-SNMP-LTNG-MIB
use constant mbgLantimeNG   => mbgSnmpRoot . '.30';

use constant mbgLtNgInfo    => mbgLantimeNG . '.0.0';

use constant mbgLtNgFirmwareVersion => mbgLtNgInfo . '.2.0';
use constant mbgLtNgSerialNumber    => mbgLtNgInfo . '.3.0';

our $mibSupport = [
    {
        name        => "meinberg",
        sysobjectid => getRegexpOidMatch(mbgSnmpRoot),
    },
];

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    my ($self) = @_;

    return 'Meinberg';
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless $device->{DESCRIPTION} =~ /^Meinberg (.+) V[0-9.]+$/i;
    return trimWhitespace($1);
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(mbgLtNgSerialNumber));
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(mbgLtNgFirmwareVersion));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Meinberg - Inventory module for Meinberg devices

=head1 DESCRIPTION

This provides Meinberg industrial modules support.
