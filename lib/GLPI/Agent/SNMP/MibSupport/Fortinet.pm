package GLPI::Agent::SNMP::MibSupport::Fortinet;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# FORTINET-CORE-MIB
use constant fortinet   => '.1.3.6.1.4.1.12356';
use constant fnCoreMib  => fortinet . '.100';
use constant fnSysSerial    => fnCoreMib . '.1.1.1.0';

# FORTINET-FORTIGATE-MIB
use constant fnFortiGateMib => fortinet . '.101';
use constant fgHighAvailability => fnFortiGateMib . '.13';
use constant fgHaStatsEntry => fgHighAvailability . '.2.1.1';

use constant fgHaStatsIndex     => fgHaStatsEntry . '.1';
use constant fgHaStatsSerial    => fgHaStatsEntry . '.2';
use constant fgHaStatsHostname  => fgHaStatsEntry . '.11';

# FORTINET-FORTIAP-MIB (Series F & G)
use constant fnFortiAPMib   => fortinet . '.120';
use constant fnApGSerial    => fnFortiAPMib . '.1.2.0';
use constant fnApGFirmware  => fnFortiAPMib . '.1.1.0';

our $mibSupport = [
    {
        name        => "fortinet",
        # FortiGate (.101)
        sysobjectid => getRegexpOidMatch(fnFortiGateMib)
    },
    {
        name        => "fortiAP",
        # FortiAP F/G Serie (.120)
        sysobjectid => getRegexpOidMatch(fnFortiAPMib)
    }
];

sub getComponents {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless ref($device->{COMPONENTS}) eq 'HASH' &&
                  ref($device->{COMPONENTS}->{COMPONENT}) eq 'ARRAY';

    my @components;
    my $components = $device->{COMPONENTS}->{COMPONENT};

    if (scalar @{$components}) {
        # Replace components with found HA devices
        my $index = $self->walk(fgHaStatsIndex);
        if (ref($index) eq "HASH") {
            my @index = sort values(%{$index});
            foreach my $index (@index) {
                my $serial = getCanonicalString($self->get(fgHaStatsSerial.".".$index))
                    or next;
                push @components, {
                    INDEX            => $index,
                    NAME             => getCanonicalString($self->get(fgHaStatsHostname.".".$index)),
                    CONTAINEDININDEX => 0,
                    SERIAL           => $serial,
                    MODEL            => $device->{MODEL},
                    TYPE             => 'chassis',
                };
            }
            return unless @components;
            delete $device->{COMPONENTS};
        }
    }

    return \@components;
}

sub getSerial {
    my ($self) = @_;

    if ($self->is("fortiAP")) {
        my $serial = getCanonicalString($self->get(fnApGSerial));
        return $serial unless empty($serial);
    }

    return getCanonicalString($self->get(fnSysSerial));
}

sub getFirmware {
    my ($self) = @_;

    return unless $self->is("fortiAP");

    return getCanonicalString($self->get(fnApGFirmware));
}


1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Fortinet - Inventory module for Fortinet devices

=head1 DESCRIPTION

The module enhances Fortinet devices support.
