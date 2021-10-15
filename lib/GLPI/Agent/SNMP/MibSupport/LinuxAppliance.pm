package FusionInventory::Agent::SNMP::MibSupport::LinuxAppliance;

use strict;
use warnings;

use parent 'FusionInventory::Agent::SNMP::MibSupportTemplate';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::SNMP;

use constant    iso         => '.1.3.6.1.2.1';
use constant    enterprises => '.1.3.6.1.4.1' ;
use constant    linux       => enterprises . '.8072.3.2.10' ;

use constant    ucddavis    => enterprises . '.2021' ;
use constant    checkpoint  => enterprises . '.2620' ;
use constant    synology    => enterprises . '.6574' ;
use constant    ubnt        => enterprises . '.41112' ;

use constant    ucdExperimental => ucddavis . '.13' ;

# UCD-DLMOD-MIB DEFINITIONS
use constant    ucdDlmodMIB => ucdExperimental . '.14' ;
use constant    dlmodEntry  => ucdDlmodMIB . '.2.1' ;
use constant    dlmodName   => dlmodEntry . '.2.1' ;

# SYNOLOGY-SYSTEM-MIB
use constant    dsmInfo              => synology . '.1.5';
use constant    dsmInfo_modelName    => dsmInfo . '.1.0';
use constant    dsmInfo_serialNumber => dsmInfo . '.2.0';
use constant    dsmInfo_version      => dsmInfo . '.3.0';

# CHECKPOINT-MIB
use constant    svnProdName                 => checkpoint  . '.1.6.1.0';
use constant    svnVersion                  => checkpoint  . '.1.6.4.1.0';
use constant    svnApplianceSerialNumber    => checkpoint  . '.1.6.16.3.0';
use constant    svnApplianceModel           => checkpoint  . '.1.6.16.7.0';
use constant    svnApplianceManufacturer    => checkpoint  . '.1.6.16.9.0';

# SNMP-FRAMEWORK-MIB
use constant    snmpModules     => '.1.3.6.1.6.3';
use constant    snmpEngine      => snmpModules . '.10.2.1';
use constant    snmpEngineID    => snmpEngine . '.1.0';

# HOST-RESOURCES-MIB
use constant    hrStorageEntry  => iso . '.25.2.3.1.3';
use constant    hrSWRunName     => iso . '.25.4.2.1.2';

# UBNT-UniFi-MIB
use constant    ubntUniFi               => ubnt . '.1.6' ;
use constant    unifiApSystemModel      => ubntUniFi . '.3.3.0' ;
use constant    unifiApSystemVersion    => ubntUniFi . '.3.6.0' ;

our $mibSupport = [
    {
        name        => "linux",
        sysobjectid => getRegexpOidMatch(linux)
    }
];

sub getType {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Seagate NAS detection
    my $hrStorageEntry = $self->walk(hrStorageEntry);
    if ($hrStorageEntry && grep { m|^/lacie|i } values(%{$hrStorageEntry})) {
        $device->{_Appliance} = {
            MODEL           => 'Seagate NAS',
            MANUFACTURER    => 'Seagate'
        };
        return 'STORAGE';
    }

    # Quescom detection
    my $dlmodName = $self->get(dlmodName);
    if ($dlmodName && $dlmodName eq 'QuesComSnmpObject') {
        $device->{_Appliance} = {
            MODEL           => 'QuesCom',
            MANUFACTURER    => 'QuesCom'
        };
        return 'NETWORKING';
    }

    # Synology detection
    my $dsmInfo_modelName = $self->get(dsmInfo_modelName);
    if ($dsmInfo_modelName) {
        $device->{_Appliance} = {
            MODEL           => $dsmInfo_modelName,
            MANUFACTURER    => 'Synology'
        };
        return 'STORAGE';
    }

    # CheckPoint detection
    my $svnApplianceManufacturer = $self->get(svnApplianceManufacturer);
    if ($svnApplianceManufacturer) {
        $device->{_Appliance} = {
            MODEL           => $self->get(svnApplianceModel),
            MANUFACTURER    => 'CheckPoint'
        };
        return 'NETWORKING';
    }

    # Sophos detection, just lookup for an existing process
    if ($self->_hasProcess('mdw.plx')) {
        $device->{_Appliance} = {
            MODEL           => 'Sophos UTM',
            MANUFACTURER    => 'Sophos'
        };
        return 'NETWORKING';
    }

    # UniFi AP detection
    my $unifiModel = $self->get(unifiApSystemModel);
    if ($unifiModel) {
        $device->{_Appliance} = {
            MODEL           => $unifiModel,
            MANUFACTURER    => 'Ubiquiti'
        };
        return 'NETWORKING';
    }
}

sub _hasProcess {
    my ($self, $name) = @_;

    return unless $name;

    # Cache the walk result in the case we have to answer many _hasProcess() calls
    $self->{hrSWRunName} ||= $self->walk(hrSWRunName);

    return unless $self->{hrSWRunName};

    return any { getCanonicalString($_) eq $name } values(%{$self->{hrSWRunName}});
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless $device->{_Appliance} && $device->{_Appliance}->{MODEL};
    return $device->{_Appliance}->{MODEL};
}

sub getManufacturer {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless $device->{_Appliance} && $device->{_Appliance}->{MANUFACTURER};
    return $device->{_Appliance}->{MANUFACTURER};
}

sub getSerial {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $manufacturer = $self->getManufacturer()
        or return;

    my $serial;

    if ($manufacturer eq 'Synology') {
        $serial = $self->get(dsmInfo_serialNumber);
    } elsif ($manufacturer eq 'CheckPoint') {
        $serial = $self->get(svnApplianceSerialNumber);
    } elsif ($manufacturer eq 'Seagate') {
        my $snmpEngineID = $self->get(snmpEngineID);
        if ($snmpEngineID) {
            # Use stripped snmpEngineID as serial when found
            $snmpEngineID =~ s/^0x//;
            $serial = $snmpEngineID;
        }
    } elsif ($manufacturer eq 'Ubiquiti' && $device->{MAC}) {
        $serial = $device->{MAC};
        $serial =~ s/://g;
    }

    return $serial;
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $manufacturer = $self->getManufacturer()
        or return;

    my $firmware;
    if ($manufacturer eq 'Synology') {
        $firmware = {
            NAME            => "$manufacturer DSM",
            DESCRIPTION     => "$manufacturer DSM firmware",
            TYPE            => "system",
            VERSION         => getCanonicalString($self->get(dsmInfo_version)),
            MANUFACTURER    => $manufacturer
        };
    } elsif ($manufacturer eq 'CheckPoint') {
        $firmware = {
            NAME            => getCanonicalString($self->get(svnProdName)),
            DESCRIPTION     => "$manufacturer SVN version",
            TYPE            => "system",
            VERSION         => getCanonicalString($self->get(svnVersion)),
            MANUFACTURER    => $manufacturer
        };
    } elsif ($manufacturer eq 'Ubiquiti') {
        $firmware = {
            NAME            => $self->getModel(),
            DESCRIPTION     => "Unifi AP System version",
            TYPE            => "system",
            VERSION         => getCanonicalString($self->get(unifiApSystemVersion)),
            MANUFACTURER    => $manufacturer
        };
    }
    $device->addFirmware($firmware) if $firmware;
}

1;

__END__

=head1 NAME

FusionInventory::Agent::SNMP::MibSupport::LinuxAppliance - Inventory module for Linux Appliances

=head1 DESCRIPTION

The module tries to enhance the Linux Appliances support.
