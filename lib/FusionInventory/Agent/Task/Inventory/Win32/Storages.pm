package FusionInventory::Agent::Task::Inventory::Win32::Storages;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Generic;
use FusionInventory::Agent::Tools::Win32;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{storage};
    return 1;
}

sub isEnabledForRemote {
    my (%params) = @_;
    return 0 if $params{no_category}->{storage};
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $hdparm = $inventory->getRemote() ? 0 : canRun('hdparm');

    foreach my $storage (_getDrives(class => 'Win32_DiskDrive')) {
        if ($hdparm && defined($storage->{NAME}) && $storage->{NAME} =~ /(\d+)$/) {
            my $info = getHdparmInfo(
                device => "/dev/hd" . chr(ord('a') + $1),
                logger => $logger
            );
            for my $k (qw(MODEL FIRMWARE SERIALNUMBER DISKSIZE)) {
                $storage->{$k} = $info->{$k} if defined $info->{$k};
            }
        }

        $inventory->addEntry(
            section => 'STORAGES',
            entry   => $storage
        );
    }

    foreach my $storage (_getDrives(class => 'Win32_CDROMDrive')) {
        if ($hdparm && $storage->{NAME} =~ /(\d+)$/) {
            my $info = getHdparmInfo(
                device => "/dev/scd" . chr(ord('a') + $1),
                logger => $logger
            );
            $storage->{MODEL}    = $info->{model}    if $info->{model};
            $storage->{FIRMWARE} = $info->{firmware} if $info->{firmware};
            $storage->{SERIAL}   = $info->{serial}   if $info->{serial};
            $storage->{DISKSIZE} = $info->{size}     if $info->{size};
        }

        $inventory->addEntry(
            section => 'STORAGES',
            entry   => $storage
        );
    }

    foreach my $storage (_getDrives(class => 'Win32_TapeDrive')) {
        $inventory->addEntry(
            section => 'STORAGES',
            entry   => $storage
        );
    }
}

sub _getDrives {
    my (%params) = @_;

    my @drives;

    foreach my $object (getWMIObjects(
        class      => $params{class},
        properties => [ qw/
            Manufacturer Model Caption Description Name MediaType InterfaceType
            FirmwareRevision SerialNumber Size
            SCSIPort SCSILogicalUnit SCSITargetId
        / ]
    )) {

        my $drive = {
            MANUFACTURER => $object->{Manufacturer},
            MODEL        => $object->{Model} || $object->{Caption},
            DESCRIPTION  => $object->{Description},
            NAME         => $object->{Name},
            TYPE         => $object->{MediaType},
            INTERFACE    => $object->{InterfaceType},
            FIRMWARE     => $object->{FirmwareRevision},
            SCSI_COID    => $object->{SCSIPort},
            SCSI_LUN     => $object->{SCSILogicalUnit},
            SCSI_UNID    => $object->{SCSITargetId},
        };

        # Cleanup field which may contain spaces
        $drive->{FIRMWARE} =~ s/\s+$//
            if $drive->{FIRMWARE};

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

        push @drives, $drive;
    }

    return @drives;
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
