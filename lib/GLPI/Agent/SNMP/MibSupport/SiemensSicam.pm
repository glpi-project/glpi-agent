package GLPI::Agent::SNMP::MibSupport::SiemensSicam;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See SIEMENS-SMI
use constant siemens    => '.1.3.6.1.4.1.22638';
use constant siemensCommon  => siemens . '.11';

# See DGPI-MIB MIB
use constant dgpiProdComp   => siemensCommon . '.1.2';
use constant dgpiProdCompEntry  => dgpiProdComp . '.1.1';
use constant dgpiProdCompContainedIn    => dgpiProdCompEntry . '.2';
use constant dgpiProdCompClass          => dgpiProdCompEntry . '.3';
use constant dgpiProdCompName           => dgpiProdCompEntry . '.4';
use constant dgpiProdCompDescription    => dgpiProdCompEntry . '.5';
use constant dgpiProdCompOrderNumber    => dgpiProdCompEntry . '.6';
use constant dgpiProdCompSerialNumber   => dgpiProdCompEntry . '.7';
use constant dgpiProdCompVersion        => dgpiProdCompEntry . '.8';
use constant dgpiProdCompHwSlot         => dgpiProdCompEntry . '.9';

our $mibSupport = [
    {
        name        => "siemens_sicam",
        # sysobjectid may be returned as string with missing first dot
        sysobjectid => qr/^\.?1\.3\.6\.1\.4\.1\.22638/,
    }
];

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{MANUFACTURER};
    return 'Siemens';
}

sub _getDescriptionData {
    my ($self, $info) = @_;

    return unless $info && $info =~ /^model|hwrev|fw|sn$/;

    my $infokey = "_$info";
    return $self->{$infokey} unless empty($self->{$infokey});

    unless ($self->{_infos}) {
        my $device = $self->device
            or return;
        return unless $device->{DESCRIPTION} && $device->{DESCRIPTION} =~ /^Siemens AG,/;
        $self->{_infos} = [ split(/\s*,\s*/, $device->{DESCRIPTION}) ];
    }
    return unless $self->{_infos};

    $self->{_model} = join(" ", $self->{_infos}->[1], $self->{_infos}->[2]);
    $self->{_hwrev} = $self->{_infos}->[3];
    $self->{_fw} = $1 if $self->{_infos}->[4] && $self->{_infos}->[4] =~ /^FW:\s+(\S.*)$/;
    $self->{_sn} = $1 if $self->{_infos}->[5] && $self->{_infos}->[5] =~ /^SN:\s+(\S.*)$/;

    return $self->{$infokey};
}

sub getModel {
    my ($self) = @_;

    return $self->_getDescriptionData("model");
}

sub getSerial {
    my ($self) = @_;

    return $self->_getDescriptionData("sn");
}

sub getFirmware {
    my ($self) = @_;

    return $self->_getDescriptionData("fw");
}

sub getComponents {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # ProdCompClass syntax
    my %ProdCompClass = (
        1,  "hwProduct",
        2,  "swProduct",
        3,  "mainHwComponent",
        4,  "extensionHwComponent",
        5,  "updatableHwComponent",
        6,  "mainFwSwComponent",
        7,  "extensionFwSwComponent",
        8,  "configurationComponent",
    );

    my $dgpiProdCompContainedIn  = $self->walk(dgpiProdCompContainedIn);
    my $dgpiProdCompClass        = $self->walk(dgpiProdCompClass);
    my $dgpiProdCompName         = $self->walk(dgpiProdCompName);
    my $dgpiProdCompDescription  = $self->walk(dgpiProdCompDescription);
    my $dgpiProdCompOrderNumber  = $self->walk(dgpiProdCompOrderNumber);
    my $dgpiProdCompSerialNumber = $self->walk(dgpiProdCompSerialNumber);
    my $dgpiProdCompVersion      = $self->walk(dgpiProdCompVersion);
    my $dgpiProdCompHwSlot       = $self->walk(dgpiProdCompHwSlot);

    my @components;
    my @firmwares;

    foreach my $key (sort { $a <=> $b } keys(%{$dgpiProdCompContainedIn})) {
        my $name = trimWhitespace(getCanonicalString($dgpiProdCompName->{$key}));
        my $serial = trimWhitespace(getCanonicalString($dgpiProdCompSerialNumber->{$key} // ""));
        my $version = trimWhitespace(getCanonicalString($dgpiProdCompVersion->{$key} // $dgpiProdCompOrderNumber->{$key} // ""));
        my $type = $ProdCompClass{$dgpiProdCompClass->{$key}} // "unknown";
        my $component = {
            CONTAINEDININDEX => $dgpiProdCompContainedIn->{$key},
            INDEX            => int($key),
            NAME             => $name,
            TYPE             => $type,
        };
        $component->{SERIAL} = $serial unless empty($serial);

        unless (empty($version)) {
            $component->{FIRMWARE} = $version;
            my $description = trimWhitespace(getCanonicalString($dgpiProdCompDescription->{$key})) || $name;
            my $slot = trimWhitespace(getCanonicalString($dgpiProdCompHwSlot->{$key})) || "";
            $description .= " on $slot slot" unless empty($slot);
            push @firmwares, {
                NAME            => $name,
                DESCRIPTION     => $description,
                TYPE            => $type,
                VERSION         => $version,
                MANUFACTURER    => $device->{MANUFACTURER}
            };
        }

        push @components, $component;
    }

    # Replace FIRMWARES section
    if (@firmwares) {
        delete $device->{FIRMWARES};
        map { $device->addFirmware($_) } @firmwares;
    }

    return \@components;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::SiemensSicam - Inventory module for Siemens Sicam devices

=head1 DESCRIPTION

This provides Siemens Sicam devices.
