package GLPI::Agent::SNMP::MibSupport::HPNetPeripheral;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See HP-LASERJET-COMMON-MIB / JETDIRECT3-MIB
use constant    hpPeripheral    => '.1.3.6.1.4.1.11.2.3.9' ; # hp.nm.system.net-peripheral
use constant    hpOfficePrinter => '.1.3.6.1.4.1.29999' ;
use constant    hpSystem        => '.1.3.6.1.4.1.11.1' ;
use constant    hpNetPrinter    => hpPeripheral . '.1' ;
use constant    hpDevice        => hpPeripheral . '.4.2.1' ; # + netPML.netPMLmgmt.device

use constant    gdStatusId      => hpNetPrinter . '.1.7.0' ;

# System id
use constant    systemId        => hpDevice . '.1.3' ;       # + system.id
use constant    model_name      => systemId . '.2.0' ;
use constant    serial_number   => systemId . '.3.0' ;
use constant    fw_rom_datecode => systemId . '.5.0' ;
use constant    fw_rom          => systemId . '.6.0' ;

# Status print engine: status-prt-eng
use constant    statusPrtEngine => hpDevice . '.4.1.2' ;
use constant    totalEnginePageCount => statusPrtEngine . '.5.0' ;
use constant    totalColorPageCount  => statusPrtEngine . '.7.0' ;
use constant    duplexPageCount      => statusPrtEngine . '.22.0' ;

# HP LaserJet Pro MFP / Marvel ASIC
use constant    hpLaserjetProMFP => '.1.3.6.1.4.1.26696.1' ;

my %counters = (
    TOTAL   => totalEnginePageCount,
    COLOR   => totalColorPageCount,
    DUPLEX  => duplexPageCount
);

our $mibSupport = [
    {
        name        => "hp-peripheral",
        sysobjectid => getRegexpOidMatch(hpPeripheral)
    },
    {
        name        => "hp-office",
        sysobjectid => getRegexpOidMatch(hpOfficePrinter)
    },
    {
        name        => "hp-system",
        sysobjectid => getRegexpOidMatch(hpSystem)
    },
    {
        name        => "hp-laserjet-pro-mfp",
        sysobjectid => getRegexpOidMatch(hpLaserjetProMFP)
    }
];

sub getManufacturer {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{MANUFACTURER};

    return "Hewlett-Packard";
}

sub getFirmware {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $firmware = $self->_getClean(fw_rom);

    # Eventually extract EEPROM revision from device description
    if (!$firmware && $device->{DESCRIPTION}) {
        foreach (split(/,+/, $device->{DESCRIPTION})) {
            return $1 if /EEPROM\s+(\S+)/;
        }
    }

    return $firmware;
}

sub getFirmwareDate {
    my ($self) = @_;

    return $self->_getClean(fw_rom_datecode);
}

sub getSerial {
    my ($self) = @_;

    return $self->get(serial_number);
}

sub getModel {
    my ($self) = @_;

    # Try first to get model if set in StatusId string
    my $statusId = getCanonicalString($self->get(gdStatusId));
    if ($statusId) {
        foreach (split(/\s*;\s*/, $statusId)) {
            return $1 if /^MODEL:\s*(.*)$/;
        }
    }

    # Else try to get model from model-name string
    return $self->_getClean(model_name);
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Update counters if still not found
    foreach my $counter (keys %counters) {
        next if $device->{PAGECOUNTERS} && $device->{PAGECOUNTERS}->{$counter};
        my $count = $self->get($counters{$counter})
            or next;
        $device->{PAGECOUNTERS}->{$counter} = getCanonicalConstant($count);
    }
}

sub _getClean {
    my ($self, $oid) = @_;

    my $clean_string = hex2char($self->get($oid));

    return unless defined $clean_string;

    $clean_string =~ s/[[:^print:]]//g;

    return $clean_string;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::HPNetPeripheral - Inventory module for HP Printers

=head1 DESCRIPTION

The module enhances HP printers devices support.
