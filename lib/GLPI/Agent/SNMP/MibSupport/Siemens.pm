package GLPI::Agent::SNMP::MibSupport::Siemens;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant sysdescr       => '.1.3.6.1.2.1.1.1.0';

use constant ad             => '.1.3.6.1.4.1.4196';
use constant siemens        => '.1.3.6.1.4.1.4329';

use constant iAsiLinkMib    => ad . '.1.1.8.3.100';
use constant snGen          => iAsiLinkMib . '.1.8';
use constant snTcpIp        => iAsiLinkMib . '.1.10';

use constant snSwVersion        => snGen . '.4.0';
use constant snInfoSerialNr     => snGen . '.6.0';
use constant snInfoMLFBNr       => snGen . '.26.0';
use constant snMacAddressBase   => snTcpIp . '.10.0';

use constant snAsiLinkPnioDeviceName    => iAsiLinkMib . '.2.21.2.0';

use constant moduleMLFB     => siemens . '.6.3.2.1.1.2.0';
use constant moduleSerial   => siemens . '.6.3.2.1.1.3.0';
use constant moduleFirmware => siemens . '.6.3.2.1.1.5.0';

# Standard MIB support for Siemens modules is sometime bad so it reports a
# sysObjectID of ".0.0"

our $mibSupport = [
    {
        name        => "siemens",
        sysobjectid => qr/^\.1\.3\.6\.1\.4\.1\.4196.*|\.0\.0$/,
    }
];

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    return 'Siemens';
}

sub getModel {
    my ($self) = @_;

    my %MLFB = (
        '6GK1 411-2AB10'        => "IE/AS-i LINK PN IO",
        '6GK7 343-1CX10-0XE0'   => "CP 343-1 Lean",
        '6ES7 318-3EL01-0AB0'   => "CPU319-3 PN/DP",
    );

    my $mlfb = getCanonicalString($self->get(snInfoMLFBNr) || $self->get(moduleMLFB));
    unless ($mlfb) {
        my @sysdescr = $self->_getInfosFromDescr();
        $mlfb = $sysdescr[3] if $sysdescr[3];
    }
    return unless $mlfb;
    return $MLFB{$mlfb} if $MLFB{$mlfb};

    return "Siemens module (PartNumber: $mlfb)";
}

sub _getInfosFromDescr {
    my ($self, $info_re) = @_;

    my $sysdescr = getCanonicalString($self->get(sysdescr));
    my @sysdescr = split(/\s*,\s*/, $sysdescr);

    if ($info_re) {
        my ($match) = grep { $_ =~ $info_re } @sysdescr;
        ($match) = $match =~ $info_re if $match;
        return $match // '';
    }

    return @sysdescr;
}

sub getSnmpHostname {
    my ($self) = @_;

    my $name = getCanonicalString($self->get(snAsiLinkPnioDeviceName));
    return $name if $name;

    my $serial = $self->getSerial()
        or return;

    return $serial;
}

sub getSerial {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $serial = getCanonicalString($self->get(snInfoSerialNr) || $self->get(moduleSerial));
    unless ($serial) {
        my @sysdescr = $self->_getInfosFromDescr();
        $serial = $sysdescr[6] if $sysdescr[6];
    }

    return $serial if $serial && $serial !~ /not set/;

    $serial = $self->getMacAddress()
        or return;
    $serial =~ s/[:]//g;
    return $serial if $serial;
}

sub getMacAddress {
    my ($self) = @_;

    return getCanonicalMacAddress($self->get(snMacAddressBase));
}

sub getFirmware {
    my ($self) = @_;

    my $version = getCanonicalString($self->get(snSwVersion) || $self->get(moduleFirmware));
    unless ($version) {
        $version = $self->_getInfosFromDescr(qr/^FW: (.*)$/);
    }

    return $version;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Siemens - Inventory module for Siemens

=head1 DESCRIPTION

This provides Siemens industrial modules support.
