package GLPI::Agent::SNMP::MibSupport::SnmpFramework;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::SNMP::Hardware;
use GLPI::Agent::Tools::SNMP;

# Leave a change to other modules to set more accurate values
use constant priority => 100;

# SNMP-FRAMEWORK-MIB
use constant    snmpModules     => '.1.3.6.1.6.3';

use constant    snmpFrameworkMIB    => snmpModules . '.10';

use constant    snmpFrameworkMIBObjects     => snmpFrameworkMIB . '.2';
use constant    snmpFrameworkMIBConformance => snmpFrameworkMIB . '.3';

use constant    snmpEngineID    => snmpFrameworkMIBObjects . '.1.1.0';

use constant    snmpFrameworkMIBCompliance  => snmpFrameworkMIBConformance . '.1.1';

# ENTITY-MIB
use constant    entPhysicalSerialNum    => '.1.3.6.1.2.1.47.1.1.1.1.11';

# PRINTER-MIB
use constant    prtGeneralSerialNumber  => '.1.3.6.1.2.1.43.5.1.1.17';

our $mibSupport = [
    {
        name    => "snmp-framework",
        oid     => snmpFrameworkMIBCompliance
    }
];

sub _engineIdDevice {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return $device if $device->{_engineId};

    my $snmpEngineID = hex2char($self->get(snmpEngineID));
    $snmpEngineID = hex2char("0x".$snmpEngineID) if defined($snmpEngineID) && $snmpEngineID =~ /^[0-9a-fA-F]+$/ && !(length($snmpEngineID)%2);

    $device->{_engineId} = $snmpEngineID;

    return if empty($snmpEngineID) || length($snmpEngineID) < 4;

    my @decode = unpack("C5", $snmpEngineID);
    my $manufacturerid = (($decode[0] & 0x7f) * 16777216) + ($decode[1] * 65536) + $decode[2] * 256 + $decode[3];
    my $match = getManufacturerIDInfo($manufacturerid);
    if ($match && $match->{manufacturer} && $match->{type}) {
        $device->{_engineIdData} = {
            MODEL           => $match->{model} // "",
            MANUFACTURER    => $match->{manufacturer}
        };
        if ($decode[0] & 0x80 && length($snmpEngineID) >= 5) {
            my $remaining = substr($snmpEngineID, 5);
            unless (empty($remaining)) {
                if ($decode[4] == 3) {
                    # Remaining is a MAC to be used as serial
                    $device->{_engineIdData}->{SERIAL} = getCanonicalMacAddress($remaining);
                } elsif ($decode[4] == 4) {
                    # Remaining is text, administratively assigned
                    $device->{_engineIdData}->{SERIAL} = getCanonicalString($remaining);
                } elsif ($decode[4] == 5) {
                    # Remaining is bytes, administratively assigned
                    $device->{_engineIdData}->{SERIAL} = unpack("H*", $remaining);
                } elsif ($decode[4] >= 128) {
                    # Remaining is device specific, just get an hex-string for the bytes
                    $device->{_engineIdData}->{SERIAL} = unpack("H*", $remaining);
                }
            }
        }
    }

    return $device;
}

sub getSerial {
    my ($self) = @_;

    my $device = $self->_engineIdDevice()
        or return;

    return unless empty($device->{SERIAL}) && defined($device->{_engineIdData}) && defined($device->{_engineIdData}->{SERIAL});

    # Entity or printer mib discovered serial is still mandatory
    my $serial = getCanonicalString($device->get_first(entPhysicalSerialNum) || $device->get_first(prtGeneralSerialNumber));
    return $serial unless empty($serial);

    return $device->{_engineIdData}->{SERIAL};
}

sub getModel {
    my ($self) = @_;

    my $device = $self->_engineIdDevice()
        or return;

    return unless empty($device->{MODEL}) && defined($device->{_engineIdData}) && defined($device->{_engineIdData}->{MODEL});

    return $device->{_engineIdData}->{MODEL};
}

sub getManufacturer {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless empty($device->{MANUFACTURER}) && defined($device->{_engineIdData}) && defined($device->{_engineIdData}->{MANUFACTURER});

    return $device->{_engineIdData}->{MANUFACTURER};
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::SnmpFramework - Inventory module for devices supporting SNMP-FRAWAMEWORK-MIB

=head1 DESCRIPTION

The module tries to enhance SNMP-FRAWAMEWORK-MIB support.
