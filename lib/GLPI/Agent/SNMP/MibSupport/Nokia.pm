package GLPI::Agent::SNMP::MibSupport::Nokia;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See TIMETRA-GLOBAL-MIB
use constant    timetra     => '.1.3.6.1.4.1.6527' ;
use constant    tmnxSRObjs  => timetra . '.3.1.2';

# See TIMETRA-CHASSIS-MIB
use constant    tmnxHwEntry         => tmnxSRObjs . '.2.1.8.1' ;

use constant    tmnxHwSerialNumber          => tmnxHwEntry . '.5.1';
use constant    tmnxHwClass                 => tmnxHwEntry . '.7.1';
use constant    tmnxHwName                  => tmnxHwEntry . '.8.1';
use constant    tmnxHwContainedIn           => tmnxHwEntry . '.13.1';
use constant    tmnxHwBootCodeVersion       => tmnxHwEntry . '.20.1';
use constant    tmnxHwSoftwareCodeVersion   => tmnxHwEntry . '.21.1';

# See SYSTEM-MIB
use constant    alcatel => '.1.3.6.1.4.1.637' ;
use constant    asam    => alcatel . '.61.1' ;

# See ASAM-EQUIP-MIB
use constant    asamEquipmentMIB    => asam . '.23';

use constant    eqptHolderSerialNumber  => asamEquipmentMIB . '.2.1.13';

our $mibSupport = [
    {
        name        => "alcatel",
        sysobjectid => getRegexpOidMatch(alcatel)
    },
    {
        name        => "nokia",
        sysobjectid => getRegexpOidMatch(timetra)
    },
];

sub getManufacturer {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return $device->{DESCRIPTION} =~ /Nokia/ ? "Nokia" : "Alcatel";
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless $device->{DESCRIPTION} =~ /Nokia/;
    my ($model) = $device->{DESCRIPTION} =~ /Nokia\s+(.+\s+)Copyright/i;
    return trimWhitespace($model);
}

sub getType {
    return 'NETWORKING';
}

sub _chassisKey {
    my ($self) = @_;

    return $self->{_chassisKey} unless empty($self->{_chassisKey});

    return if exists($self->{_chassisKey}) && empty($self->{_chassisKey});

    my $tmnxHWContainedIn = $self->walk(tmnxHwContainedIn);

    # Chassis key is the one which is not contained in any container: its value is "0"
    $self->{_chassisKey} = first {
        !empty($tmnxHWContainedIn->{$_}) && !$tmnxHWContainedIn->{$_}
    } keys(%{$tmnxHWContainedIn});
}

sub getSerial {
    my ($self) = @_;

    # First try to report Nokia ISAM S/N
    my $eqptHolderSerialNumber = $self->walk(eqptHolderSerialNumber);
    if ($eqptHolderSerialNumber) {
        my @keys = sort { $a <=> $b } keys(%{$eqptHolderSerialNumber});
        my $key = first {
            !empty($eqptHolderSerialNumber->{$_}) && $eqptHolderSerialNumber->{$_} !~ /^NOT.AVAILABLE$/i
        } @keys;
        return getCanonicalString($eqptHolderSerialNumber->{$key}) unless empty($key);
    }

    my $chassisKey = $self->_chassisKey;
    return if empty($chassisKey);

    return getCanonicalString($self->get(tmnxHwSerialNumber.".".$chassisKey));
}

sub _recursiveSortedKeys {
    my ($self, $key) = @_;

    return unless $self->_chassisKey;

    return $self->_recursiveSortedKeys($self->_chassisKey)
        unless $key;

    my @list = ($key);

    my @subkeys = grep {
        $self->{_containedIn}->{$_} && $self->{_containedIn}->{$_} eq $key
    } sort { $a <=> $b } keys(%{$self->{_containedIn}});

    return @list unless @subkeys;

    foreach my $subkey (@subkeys) {
        push @list, $self->_recursiveSortedKeys($subkey);
    }

    return @list;
}

sub getFirmware {
    my ($self) = @_;

    # Try first to extract first description word from description if it contains Nokia
    my $device = $self->device;
    if ($device && $device->{DESCRIPTION} =~ /Nokia/) {
        my ($firmware) = $device->{DESCRIPTION} =~ /^(\S+)/;
        return $firmware unless empty($firmware);
    }

    # Look for first tmnxHwSoftwareCodeVersion in components and return first found

    $self->{_containedIn} = $self->walk(tmnxHwContainedIn)
        or return;

    my @keys = $self->_recursiveSortedKeys()
        or return;

    my $tmnxHwSoftwareCodeVersion = $self->walk(tmnxHwSoftwareCodeVersion)
        or return;

    my $softwarekey = first { !empty($tmnxHwSoftwareCodeVersion->{$_}) } @keys;
    my $firmware = trimWhitespace(getCanonicalString($tmnxHwSoftwareCodeVersion->{$softwarekey}));
    return if empty($firmware) || $firmware !~ /^(\S+)/;
    return $1;
}

sub getComponents {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # TmnxHwClass syntax
    my %types = (
        1,  "other",
        2,  "unknown",
        3,  "physChassis",
        4,  "container",
        5,  "powerSupply",
        6,  "fan",
        7,  "sensor",
        8,  "ioModule",
        9,  "cpmModule",
        10, "fabricModule",
        11, "mdaModule",
        12, "flashDiskModule",
        13, "port",
        15, "ccm",
        19, "alarmInputModule",
        20, "pcm",
        21, "powerShelf",
        22, "powerShelfController",
        23, "cpmCarrier",
        24, "xioModule",
    );

    my $tmnxHwSerialNumber    = $self->walk(tmnxHwSerialNumber);
    my $tmnxHwClass           = $self->walk(tmnxHwClass);
    my $tmnxHwName            = $self->walk(tmnxHwName);
    my $tmnxHwBootCodeVersion = $self->walk(tmnxHwBootCodeVersion);

    $self->{_containedIn} = $self->walk(tmnxHwContainedIn)
        or return;

    my @keys = $self->_recursiveSortedKeys()
        or return;

    my @components;

    foreach my $key (@keys) {
        my $name = trimWhitespace(getCanonicalString($tmnxHwName->{$key}));
        my $serial = trimWhitespace(getCanonicalString($tmnxHwSerialNumber->{$key} // ""));
        my $firmware = trimWhitespace(getCanonicalString($tmnxHwBootCodeVersion->{$key} // ""));
        my $type = $types{$tmnxHwClass->{$key} || 2} // "unknown";
        my $component = {
            CONTAINEDININDEX => $self->{_containedIn}->{$key},
            INDEX            => int($key),
            NAME             => $name,
            TYPE             => $type,
        };
        $component->{SERIAL}   = $serial unless empty($serial);

        if (!empty($firmware) && $firmware =~ /(^\S+)/) {
            $component->{FIRMWARE} = $1;
            my $firmware = {
                NAME            => $name." bootcode",
                DESCRIPTION     => $name." bootcode version",
                TYPE            => $type,
                VERSION         => $1,
                MANUFACTURER    => $device->{MANUFACTURER}
            };
            $device->addFirmware($firmware);
        }

        push @components, $component;
    }

    return [
        sort {
            $a->{CONTAINEDININDEX} <=> $b->{CONTAINEDININDEX} && $a->{INDEX} <=> $b->{INDEX}
        } @components
    ];
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Alcattel-Nokia - Inventory module for Alcatel Nokia devices

=head1 DESCRIPTION

The module enhances Alcatel Nokia devices support.
