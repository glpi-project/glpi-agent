package GLPI::Agent::Task::Inventory::Win32::Storages;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;
use GLPI::Agent::Tools::Win32;

use constant    category    => "storage";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $hdparm = canRun('hdparm');

    my $storages = _getDrives(
        class   => 'MSFT_PhysicalDisk',
        moniker => 'winmgmts://./root/microsoft/windows/storage',
        logger  => $logger
    );
    # Fallback on Win32_DiskDrive if new class fails
    $storages = _getDrives(
        class   => 'Win32_DiskDrive',
        logger  => $logger
    ) unless @{$storages};

    foreach my $storage (@{$storages}) {
        if ($hdparm && defined($storage->{NAME}) && $storage->{NAME} =~ /(\d+)$/) {
            my $info = getHdparmInfo(
                device => "/dev/hd" . chr(ord('a') + $1),
                logger => $logger
            );
            for my $k (qw(MODEL FIRMWARE SERIALNUMBER DISKSIZE)) {
                next unless defined($info->{$k});
                $storage->{$k} = trimWhitespace($info->{$k});
            }
        }

        $inventory->addEntry(
            section => 'STORAGES',
            entry   => $storage
        );
    }

    $storages = _getDrives(
        class   => 'Win32_CDROMDrive',
        logger  => $logger
    );
    foreach my $storage (@{$storages}) {
        if ($hdparm && $storage->{NAME} =~ /(\d+)$/) {
            my $info = getHdparmInfo(
                device => "/dev/scd" . chr(ord('a') + $1),
                logger => $logger
            );
            $storage->{MODEL}    = $info->{model}    if $info->{model};
            $storage->{FIRMWARE} = trimWhitespace($info->{firmware})
                if $info->{firmware};
            $storage->{SERIAL}   = $info->{serial}   if $info->{serial};
            $storage->{DISKSIZE} = $info->{size}     if $info->{size};
        }

        $inventory->addEntry(
            section => 'STORAGES',
            entry   => $storage
        );
    }

    $storages = _getDrives(
        class   => 'Win32_TapeDrive',
        logger  => $logger
    );
    foreach my $storage (@{$storages}) {
        $inventory->addEntry(
            section => 'STORAGES',
            entry   => $storage
        );
    }
}

# Source: https://docs.microsoft.com/en-us/previous-versions/windows/desktop/stormgmt/msft-physicaldisk
my %BusTypes = qw(
    0   UNKNOWN
    1   SCSI
    2   ATAPI
    3   ATA
    4   IEEE 1394
    5   SSA
    6   Fibre Channel
    7   USB
    8   RAID
    9   iSCSI
    10  SAS
    11  SATA
    12  SD
    13  MMC
    15  File-Backed Virtual
    16  Storage Spaces
    17  NVMe
);

my %MediaTypes = qw(
    0   UNKNOWN
    3   HDD
    4   SSD
    5   SCM
);

sub _getDrives {
    my (%params) = @_;

    my @drives;

    my @properties = qw/
        Manufacturer Model Caption Description Name MediaType InterfaceType
        FirmwareRevision SerialNumber Size SCSIPort SCSILogicalUnit SCSITargetId
        BusType FriendlyName DeviceId
    /;
    push @properties, qw(FirmwareVersion PhysicalLocation)
        if $params{class} eq 'MSFT_PhysicalDisk';

    foreach my $object (getWMIObjects(
        properties => \@properties,
        %params
    )) {

        my $drive = {
            MANUFACTURER => $object->{Manufacturer},
            MODEL        => $object->{Model} || $object->{Caption} || $object->{FriendlyName},
            DESCRIPTION  => $object->{Description} || $object->{PhysicalLocation},
            NAME         => $object->{Name} // "PhysicalDisk".($object->{DeviceId}//"0"),
            TYPE         => $MediaTypes{$object->{MediaType}} || $object->{MediaType},
            INTERFACE    => $object->{InterfaceType},
            FIRMWARE     => $object->{FirmwareVersion} || $object->{FirmwareRevision},
            SCSI_COID    => $object->{SCSIPort},
            SCSI_LUN     => $object->{SCSILogicalUnit},
            SCSI_UNID    => $object->{SCSITargetId},
        };

        # Cleanup field which may contain spaces
        $drive->{FIRMWARE} = trimWhitespace($drive->{FIRMWARE}) if $drive->{FIRMWARE};

        $drive->{DISKSIZE} = int($object->{Size} / (1024 * 1024))
            if $object->{Size};

        if ($object->{SerialNumber} && $object->{SerialNumber} !~ /^ +$/) {
            # Try to decode serial only for known case
            if ($drive->{MODEL} =~ /VBOX HARDDISK ATA/) {
                $drive->{SERIAL} = _decodeSerialNumber($object->{SerialNumber});
            } else {
                $drive->{SERIAL} = $object->{SerialNumber};
            }
        }

        if (!$drive->{INTERFACE} && defined($object->{BusType})) {
            $drive->{INTERFACE} = $BusTypes{$object->{BusType}} // $BusTypes{0};
        }
        if ($drive->{MODEL} =~ /VBOX/) {
            $drive->{DESCRIPTION} = "Virtual device" unless $drive->{DESCRIPTION};
            $drive->{TYPE} = "Virtual" if $drive->{TYPE} eq 'UNKNOWN';
        }

        push @drives, $drive;
    }

    return \@drives;
}

sub _decodeSerialNumber {
    my ($serial) = @_ ;

    return $serial unless ($serial =~ /^[0-9a-f]+$/);

    # serial is a space padded string encoded in hex words (4 hex-digits by word)
    return $serial if length($serial) % 4 ;

    # Map hex-encoded string to list of chars
    my @chars = map { chr hex } unpack("(a[2])*", $serial);

    $serial = '';

    # Re-order chars
    while (@chars) {
        my $next = shift(@chars);
        $serial .= shift(@chars) . $next ;
    }

    # Strip trailing spaces
    $serial =~ s/ *$//;

    return $serial;
}

1;
