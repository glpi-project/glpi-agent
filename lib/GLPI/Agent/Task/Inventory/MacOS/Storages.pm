package GLPI::Agent::Task::Inventory::MacOS::Storages;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::MacOS;

use constant    category    => "storage";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $storage (
        _getSerialATAStorages(logger => $logger),
        _getDiscBurningStorages(logger => $logger),
        _getCardReaderStorages(logger => $logger),
        _getUSBStorages(logger => $logger),
        _getFireWireStorages(logger => $logger)
    ) {
        $inventory->addEntry(
            section => 'STORAGES',
            entry   => $storage
        );
    }
}

sub _getSerialATAStorages {
    my (%params) = @_;

    my $infos = getSystemProfilerInfos(
        type   => 'SPSerialATADataType',
        format => 'xml',
        %params
    );
    return unless $infos->{storages};
    my @storages = ();
    foreach my $hash (values %{$infos->{storages}}) {
        next unless $hash->{partition_map_type} || $hash->{detachable_drive};
        next if $hash->{_name} =~ /controller/i;
        my $storage = {
            NAME         => $hash->{bsd_name} || $hash->{_name},
            MANUFACTURER => getCanonicalManufacturer($hash->{_name}),
            TYPE         => 'Disk drive',
            INTERFACE    => 'SATA',
            SERIAL       => $hash->{device_serial},
            MODEL        => $hash->{device_model} || $hash->{_name},
            FIRMWARE     => $hash->{device_revision},
            DESCRIPTION  => $hash->{_name}
        };

        _setDiskSize($hash, $storage);

        # Cleanup manufacturer from model
        $storage->{MODEL} =~ s/\s*$storage->{MANUFACTURER}\s*//i
            if $storage->{MODEL};

        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _getDiscBurningStorages {
    my (%params) = @_;

    my @storages = ();
    my $infos = getSystemProfilerInfos(
        type   => 'SPDiscBurningDataType',
        format => 'xml',
        %params
    );
    return @storages unless $infos->{storages};

    foreach my $hash (values %{$infos->{storages}}) {
        my $storage = {
            NAME         => $hash->{bsd_name} || $hash->{_name},
            MANUFACTURER => getCanonicalManufacturer($hash->{manufacturer} || $hash->{_name}),
            TYPE         => 'Disk burning',
            INTERFACE    => $hash->{interconnect} && $hash->{interconnect} eq 'SERIAL-ATA' ? "SATA" : "ATAPI",
            MODEL        => $hash->{_name},
            FIRMWARE     => $hash->{firmware}
        };

        _setDiskSize($hash, $storage);

        # Cleanup manufacturer from model
        $storage->{MODEL} =~ s/\s*$storage->{MANUFACTURER}\s*//i
            if $storage->{MODEL};

        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _getCardReaderStorages {
    my (%params) = @_;

    my $infos = getSystemProfilerInfos(
        type   => 'SPCardReaderDataType',
        format => 'xml',
        %params
    );
    return unless $infos->{storages};

    my @storages = ();
    foreach my $hash (values %{$infos->{storages}}) {
        next if ($hash->{iocontent} || $hash->{file_system} || $hash->{mount_point}) && !$hash->{partition_map_type};
        my $storage;
        if ($hash->{_name} eq 'spcardreader') {
            $storage = {
                NAME         => $hash->{bsd_name} || $hash->{_name},
                TYPE         => 'Card reader',
                DESCRIPTION  => $hash->{_name},
                SERIAL       => $hash->{spcardreader_serialnumber},
                MODEL        => $hash->{_name},
                FIRMWARE     => $hash->{'spcardreader_revision-id'},
                MANUFACTURER => $hash->{'spcardreader_vendor-id'}
            };
        } else {
            $storage = {
                NAME         => $hash->{bsd_name} || $hash->{_name},
                TYPE         => 'SD Card',
                DESCRIPTION  => $hash->{_name},
            };
            _setDiskSize($hash, $storage);
        }
        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _getUSBStorages {
    my (%params) = @_;

    my $infos = getSystemProfilerInfos(
        type   => 'SPUSBDataType',
        format => 'xml',
        %params
    );
    return unless $infos->{storages};

    my @storages = ();
    foreach my $hash (values %{$infos->{storages}}) {
        unless ($hash->{bsn_name} && $hash->{bsd_name} =~ /^disk/) {
            next if $hash->{_name} eq 'Mass Storage Device';
            next if $hash->{_name} =~ /keyboard|controller|IR Receiver|built-in|hub|mouse|tablet|usb(?:\d+)?bus/i;
            next if ($hash->{'Built-in_Device'} && $hash->{'Built-in_Device'} eq 'Yes');
            next if ($hash->{iocontent} || $hash->{file_system} || $hash->{mount_point}) && !$hash->{partition_map_type};
        }
        my $storage = {
            NAME         => $hash->{bsd_name} || $hash->{_name},
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DESCRIPTION  => $hash->{_name},
        };

        _setDiskSize($hash, $storage);

        my $extract = _getInfoExtract($hash);
        $storage->{MODEL} = $extract->{device_model} || $hash->{_name};
        $storage->{SERIAL} = $extract->{serial_num} if $extract->{serial_num};
        $storage->{FIRMWARE} = $extract->{bcd_device} if $extract->{bcd_device};
        $storage->{MANUFACTURER} = getCanonicalManufacturer($extract->{manufacturer})
            if $extract->{manufacturer};

        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _setDiskSize {
    my ($hash, $storage) = @_;

    return unless $hash->{size_in_bytes} || $hash->{size};

    $storage->{DISKSIZE} = getCanonicalSize(
        $hash->{size_in_bytes} ? $hash->{size_in_bytes} . ' bytes' : $hash->{size},
        1024
    );
}

sub _getInfoExtract {
    my ($hash) = @_;

    my $extract = {};
    foreach my $key (keys(%{$hash})) {
        next unless defined($hash->{$key}) && $key =~ /^(?:\w_)?(serial_num|device_model|bcd_device|manufacturer|product_id)/;
        $extract->{$1} = $hash->{$key};
    }

    return $extract;
}

sub _getFireWireStorages {
    my (%params) = @_;

    my $infos = getSystemProfilerInfos(
        type   => 'SPFireWireDataType',
        format => 'xml',
        %params
    );
    return unless $infos->{storages};

    my @storages = ();
    foreach my $hash (values %{$infos->{storages}}) {
        next unless $hash->{partition_map_type};
        my $storage = {
            NAME         => $hash->{bsd_name} || $hash->{_name},
            TYPE         => 'Disk drive',
            INTERFACE    => '1394',
            DESCRIPTION  => $hash->{_name},
        };

        _setDiskSize($hash, $storage);

        my $extract = _getInfoExtract($hash);
        $storage->{MODEL} = $extract->{product_id} if $extract->{product_id};
        $storage->{SERIAL} = $extract->{serial_num} if $extract->{serial_num};
        $storage->{FIRMWARE} = $extract->{bcd_device} if $extract->{bcd_device};
        $storage->{MANUFACTURER} = getCanonicalManufacturer($extract->{manufacturer})
            if $extract->{manufacturer};

        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _sanitizedHash {
    my ($hash) = @_;
    foreach my $key (keys(%{$hash})) {
        if (defined($hash->{$key})) {
            $hash->{$key} = trimWhitespace($hash->{$key});
        } else {
            delete $hash->{$key};
        }
    }
    return $hash;
}

1;
