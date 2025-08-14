package GLPI::Agent::SNMP::MibSupport::TpLink;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    sysObjectID => '.1.3.6.1.2.1.1.2.0';

# See TPLINK-MIB

use constant    tplink  => '.1.3.6.1.4.1.11863';

use constant    switch      => tplink . '.1';
use constant    tplinkMgmt  => tplink . '.6';

use constant    l2manageswitch  => switch . '.1';

# See TPLINK-SYSINFO-MIB

use constant    tplinkSysInfoMIBObjects => tplinkMgmt . '.1.1';
use constant    tpSysInfoHwVersion      => tplinkSysInfoMIBObjects . '.5.0';
use constant    tpSysInfoSwVersion      => tplinkSysInfoMIBObjects . '.6.0';
use constant    tpSysInfoMacAddr        => tplinkSysInfoMIBObjects . '.7.0';
use constant    tpSysInfoSerialNum      => tplinkSysInfoMIBObjects . '.8.0';

# TPLINK-DOT1Q-VLAN-MIB
#.1.3.6.1.4.1.11863.6.14.1.2.1.1.1

use constant    tplinkDot1qVlanMIBObjects   => tplinkMgmt . '.14.1';

use constant    vlanPortConfig  => tplinkDot1qVlanMIBObjects . '.1';
use constant    vlanConfig      => tplinkDot1qVlanMIBObjects . '.2';

use constant    vlanPortNumber  => vlanPortConfig . '.1.1.1';

use constant    dot1qVlanId             => vlanConfig . '.1.1.1';
use constant    dot1qVlanDescription    => vlanConfig . '.1.1.2';
use constant    vlanTagPortMemberAdd    => vlanConfig . '.1.1.3';
use constant    vlanUntagPortMemberAdd  => vlanConfig . '.1.1.4';
use constant    vlanPortMemberRemove    => vlanConfig . '.1.1.5';
use constant    dot1qVlanStatus         => vlanConfig . '.1.1.6';

our $mibSupport = [
    {
        name        => "tplink",
        sysobjectid => getRegexpOidMatch(tplink)
    }
];

my $sysobjectid;

sub _getOlderSysInfo {
    my ($self, $info) = @_;
    $sysobjectid = $self->get(sysObjectID) unless $sysobjectid;
    return $self->get($sysobjectid . ".1.1.1." . $info);
}

sub getFirmware {
    my ($self) = @_;

    my $swversion = $self->get(tpSysInfoSwVersion) || $self->_getOlderSysInfo("6.0")
        or return;

    return getCanonicalString($swversion);
}

sub getMacAddress {
    my ($self) = @_;

    my $macaddr = $self->get(tpSysInfoMacAddr) || $self->_getOlderSysInfo("7.0")
        or return;

    $macaddr = getCanonicalString($macaddr);
    $macaddr =~ s/-/:/g;

    return getCanonicalMacAddress($macaddr);
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{MODEL};

    my $hwversion = $self->get(tpSysInfoHwVersion) || $self->_getOlderSysInfo("5.0")
        or return;

    $hwversion = getCanonicalString($hwversion);

    my ($model) = $hwversion =~ /^(\S+)/;

    return $model;
}

sub getSerial {
    my ($self) = @_;

    # Use the mac address string with dash separator on older TP-Link devices
    my $serial = $self->get(tpSysInfoSerialNum) || $self->_getOlderSysInfo("7.0")
        or return;

    return getCanonicalString($serial);
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $hardware_version = getCanonicalString($self->get(tpSysInfoHwVersion));
    unless (empty($hardware_version)) {
        $device->addFirmware({
            NAME            => $device->{MODEL},
            DESCRIPTION     => "TP-Link Hardware version",
            TYPE            => "hardware",
            VERSION         => $hardware_version,
            MANUFACTURER    => "TP-Link"
        });
    }

    # Older TP-Link device won't find data under recent oid and it seems we have to
    # look for values under oid given by sysObjectID
    if ($sysobjectid) {
        my $hardware_version = $self->_getOlderSysInfo("5.0");
        if ($hardware_version) {
            $device->addFirmware({
                NAME            => $device->{MODEL},
                DESCRIPTION     => "TP-Link Hardware version",
                TYPE            => "hardware",
                VERSION         => getCanonicalString($hardware_version),
                MANUFACTURER    => "TP-Link"
            });
        }
    }

    my $vlanPortNumber = $self->walk(vlanPortNumber);
    if ($vlanPortNumber) {
        my $vlans = $self->_getVlans();
        map {
            my $port = getCanonicalString($vlanPortNumber->{$_});
            $device->{PORTS}->{PORT}->{$_}->{VLANS}->{VLAN} = $vlans->{$port}
                if $device->{PORTS}->{PORT}->{$_} && $vlans->{$port} && !$device->{PORTS}->{PORT}->{$_}->{VLANS};
        } keys(%{$vlanPortNumber});
    }
}

sub _parsePortsDef {
    my ($portsDef) = @_;

    my @ports;

    foreach my $def (split(/,+/, $portsDef)) {
        $def = trimWhitespace($def);
        if ($def =~ /^(\S*)(\d+)-(\d+)$/) {
            push @ports, map { $1.$_ } $2..$3
                if $3 > $2;
        } else {
            push @ports, $def;
        }
    }

    return @ports
}

sub _getVlans {
    my ($self) = @_;

    my $results;

    my $dot1qVlanDescription = $self->walk(dot1qVlanDescription);
    my $dot1qVlanStatus = $self->walk(dot1qVlanStatus);

    if ($dot1qVlanDescription && $dot1qVlanStatus) {

        my $dot1qVlanId = $self->walk(dot1qVlanId);
        my $vlanTagPortMemberAdd = $self->walk(vlanTagPortMemberAdd);
        my $vlanUntagPortMemberAdd = $self->walk(vlanUntagPortMemberAdd);
        my $vlanPortMemberRemove = $self->walk(vlanPortMemberRemove);

        foreach my $suffix (sort keys %{$dot1qVlanStatus}) {
            next unless $dot1qVlanStatus->{$suffix} eq 1;

            my $vlan_id = getCanonicalString($dot1qVlanId->{$suffix});
            my $name = getCanonicalString($dot1qVlanDescription->{$suffix});

            my %ports;

            my $taggedDef = getCanonicalString($vlanTagPortMemberAdd->{$suffix});
            unless (empty($taggedDef)) {
                map {
                    $ports{$_}->{$vlan_id} = {
                        NUMBER  => $vlan_id,
                        NAME    => $name // '',
                        TAGGED  => 1
                    };
                } _parsePortsDef($taggedDef);
            }

            my $untaggedDef = getCanonicalString($vlanUntagPortMemberAdd->{$suffix});
            unless (empty($untaggedDef)) {
                map {
                    $ports{$_}->{$vlan_id} = {
                        NUMBER  => $vlan_id,
                        NAME    => $name // '',
                        TAGGED  => 0
                    };
                } _parsePortsDef($untaggedDef);
            }

            my $removeDef = getCanonicalString($vlanPortMemberRemove->{$suffix});
            unless (empty($removeDef)) {
                map {
                    delete $ports{$_}->{$vlan_id};
                } _parsePortsDef($removeDef);
            }

            map {
                push @{$results->{$_}}, sort { $a->{NUMBER} <=> $b->{NUMBER} } values(%{$ports{$_}})
            } keys(%ports);
        }
    }

    return $results;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::TpLink - Inventory module for TP-Link devices

=head1 DESCRIPTION

The module enhances TP-Link device support.
