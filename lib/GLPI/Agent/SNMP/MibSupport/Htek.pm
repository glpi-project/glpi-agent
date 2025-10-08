package GLPI::Agent::SNMP::MibSupport::Htek;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# UNICORN-MIB
use constant    htek => ".1.3.6.1.4.1.38241" ;

use constant    firmware    => htek . ".1.1.0";
use constant    model       => htek . ".1.2.0";
use constant    macaddr     => htek . ".1.3.0";
use constant    ip          => htek . ".1.4.0";

our $mibSupport = [
    {
        name        => "htek",
        sysobjectid => getRegexpOidMatch(htek)
    }
];

sub getMacAddress {
    my ($self) = @_;

    return getCanonicalMacAddress(getCanonicalString($self->get(macaddr)));
}

sub getFirmware {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $firmwares = getCanonicalString($self->get(firmware));
    my ($firmware) = $firmwares =~ /^BOOT--([0-9.]+)/;
    return $firmware;
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(model));
}

sub getIp {
    my ($self) = @_;

    return getCanonicalString($self->get(ip));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Fix IPS
    if (ref($device->{IPS}) eq 'HASH' && ref($device->{IPS}->{IP}) eq 'ARRAY') {
        my @ips = grep { ! empty($_) } @{$device->{IPS}->{IP}};
        $device->{IPS}->{IP} = \@ips;
    }

    # Fix hostname
    if ($device->{SNMPHOSTNAME} =~ /^\(none\)\s+Description: (\S+).*MAC\s\d:\s(\S\S \S\S \S\S \S\S \S\S \S\S) /) {
        $device->{SNMPHOSTNAME} = "$1 $2";
    }
    $device->{INFO}{NAME} = $device->{SNMPHOSTNAME}
        if $device->{INFO} && $device->{INFO}{NAME};
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Htek - Inventory module for Htek IP phones devices

=head1 DESCRIPTION

The module enhances support for Htek IP phones devices
