package GLPI::Agent::Task::Inventory::Win32::Drives;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools::Win32;

use constant    category    => "drive";

my @type = (
    'Unknown',
    'No Root Directory',
    'Removable Disk',
    'Local Disk',
    'Network Drive',
    'Compact Disc',
    'RAM Disk'
);

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $drive (_getDrives(
        logger  => $params{logger},
    )) {
        $inventory->addEntry(
            section => 'DRIVES',
            entry   => $drive
        );
    }
}

sub _getDrives {
    my (%params) = @_;

    my $logger = $params{logger};

    my $systemDrive = "C:";
    foreach my $object (getWMIObjects(
        class      => 'Win32_OperatingSystem',
        properties => [ qw/SystemDrive/ ]
    )) {
        next unless $object->{SystemDrive};
        $systemDrive = lc($object->{SystemDrive});
    }

    my @drives;
    my %seen;

    foreach my $object (getWMIObjects(
        class      => 'Win32_LogicalDisk',
        properties => [ qw/
            InstallDate Description FreeSpace FileSystem VolumeName Caption
            VolumeSerialNumber DeviceID Size DriveType VolumeName ProviderName
        / ]
    )) {

        $object->{FreeSpace} = int($object->{FreeSpace} / (1024 * 1024))
            if $object->{FreeSpace};

        $object->{Size} = int($object->{Size} / (1024 * 1024))
            if $object->{Size};

        my $filesystem = $object->{FileSystem};
        if ($object->{DriveType} == 4 && $object->{ProviderName}) {
            if ($object->{ProviderName} =~ /\\DavWWWRoot\\/) {
                $filesystem = "WebDav";
            } elsif ($object->{ProviderName} =~ /^\\\\vmware-host\\/) {
                $filesystem = "HGFS";
            } elsif (!$object->{FileSystem} || $object->{FileSystem} ne 'NFS') {
                $filesystem = "CIFS";
            }
        }

        my $drive = {
            CREATEDATE  => $object->{InstallDate},
            DESCRIPTION => $object->{Description},
            FREE        => $object->{FreeSpace},
            FILESYSTEM  => $filesystem,
            LABEL       => $object->{VolumeName},
            LETTER      => $object->{DeviceID} || $object->{Caption},
            SERIAL      => $object->{VolumeSerialNumber},
            SYSTEMDRIVE => (lc($object->{DeviceID}) eq $systemDrive),
            TOTAL       => $object->{Size},
            TYPE        => $type[$object->{DriveType}],
            VOLUMN      => $object->{VolumeName},
        };

        $seen{$object->{DeviceID} || $object->{Caption}} = $drive;

        push @drives, $drive;
    }

    # Scan Win32_Volume to check for mounted point drives
    foreach my $object (getWMIObjects(
        class      => 'Win32_Volume',
        properties => [ qw/
            InstallDate Description FreeSpace FileSystem Name Caption DriveLetter
            SerialNumber Capacity DriveType Label DeviceID
        / ]
    )) {
        # Skip volume already seen as instance of Win32_LogicalDisk class
        if (@drives && exists($object->{DriveLetter}) && $object->{DriveLetter}) {
            next if $seen{$object->{DriveLetter}};
        }

        $object->{FreeSpace} = int($object->{FreeSpace} / (1024 * 1024))
            if $object->{FreeSpace};

        $object->{Capacity} = int($object->{Capacity} / (1024 * 1024))
            if $object->{Capacity};

        my $drive = {
            CREATEDATE  => $object->{InstallDate},
            DESCRIPTION => $object->{Description},
            FREE        => $object->{FreeSpace},
            FILESYSTEM  => $object->{FileSystem},
            LABEL       => $object->{Label},
            LETTER      => $object->{Name} =~ m/^\\\\\?\\Volume/ ?
                $object->{Label} : $object->{Name} || $object->{Caption},
            SERIAL      => _encodeSerialNumber($object->{SerialNumber}),
            SYSTEMDRIVE => $object->{DriveLetter} ?
                (lc($object->{DriveLetter}) eq $systemDrive) : '',
            TOTAL       => $object->{Capacity},
            TYPE        => $type[$object->{DriveType}],
            VOLUMN      => $object->{Label},
        };

        $seen{$object->{DeviceID} || $object->{DriveLetter} || $object->{Caption}} = $drive;

        push @drives, $drive;
    }

    # See https://docs.microsoft.com/en-us/windows/desktop/secprov/getencryptionmethod-win32-encryptablevolume
    my @encryptionMethod = qw(
        None            AES_128_WITH_DIFFUSER   AES_256_WITH_DIFFUSER
        AES_128         AES_256                 HARDWARE_ENCRYPTION
        XTS_AES_128     XTS_AES_256
    );

    # Scan Win32_EncryptableVolume to check for BitLocker crypted volumes
    foreach my $object (getWMIObjects(
        moniker    => 'winmgmts://./root/CIMV2/Security/MicrosoftVolumeEncryption',
        class      => 'Win32_EncryptableVolume',
        properties => [ qw/
            DeviceID EncryptionMethod ProtectionStatus DriveLetter
        / ]
    )) {
        my $id = $object->{DeviceID};
        $id = $object->{DriveLetter} unless exists($seen{$id});

        if (!exists($seen{$id})) {
            $logger->error("Unknown $id encryptable drive") if $logger;
            next;
        }

        my $method = $object->{EncryptionMethod} || 0;
        my $encryptAlgo = defined($encryptionMethod[$method]) ?
            $encryptionMethod[$method] : 'Unknown';

        my $encrypted = defined($object->{ProtectionStatus}) ?
            $object->{ProtectionStatus} : 2 ;

        $seen{$id}->{ENCRYPT_NAME}   = 'BitLocker';
        $seen{$id}->{ENCRYPT_ALGO}   = $encryptAlgo ;
        $seen{$id}->{ENCRYPT_STATUS} = $encrypted == 0 ? 'No'  :
                                       $encrypted == 1 ? 'Yes' : 'Unknown' ;
    }

    return @drives;
}

sub _encodeSerialNumber {
    my ($serial) = @_;

    return '' unless $serial;

    # Win32_Volume serial is a uint32 but returned as signed int32 by API
    return $serial unless $serial =~ /^-?\d+$/;

    # Re-encode serial as uint32 and return hexadecimal string
    $serial = unpack('L', pack('L', $serial));

    return sprintf("%08X", $serial);
}

1;
