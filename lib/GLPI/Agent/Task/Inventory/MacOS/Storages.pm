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

    my $storages = [
        _getSerialATAStorages(logger => $logger),
        _getDiscBurningStorages(logger => $logger),
        _getCardReaderStorages(logger => $logger),
        _getUSBStorages(logger => $logger),
        _getFireWireStorages(logger => $logger)
    ];
    foreach my $storage (@$storages) {
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
        logger => $params{logger},
        file   => $params{file}
    );
    return unless $infos->{storages};
    my @storages = ();
    for my $hash (values %{$infos->{storages}}) {
        next if $hash->{_name} =~ /controller/i;
        my $storage = _extractStorage($hash);
        $storage->{TYPE} = 'Disk drive';
        $storage->{INTERFACE} = 'SATA';
        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _extractStorage {
    my ($hash) = @_;

    my $storage = {
        NAME         => $hash->{bsd_name} || $hash->{_name},
        MANUFACTURER => getCanonicalManufacturer($hash->{_name}),
#        TYPE         => $bus_name eq 'FireWire' ? '1394' : $bus_name,
        SERIAL       => $hash->{device_serial},
        MODEL        => $hash->{device_model} || $hash->{_name},
        FIRMWARE     => $hash->{device_revision},
        DISKSIZE     => _extractDiskSize($hash),
        DESCRIPTION  => $hash->{_name}
    };

    if ($storage->{MODEL}) {
        $storage->{MODEL} =~ s/\s*$storage->{MANUFACTURER}\s*//i;
    }

    return $storage;
}

sub _getDiscBurningStorages {
    my (%params) = @_;

    my @storages = ();
    my $infos = getSystemProfilerInfos(
        type   => 'SPDiscBurningDataType',
        format => 'xml',
        logger => $params{logger},
        file   => $params{file}
    );
    return @storages unless $infos->{storages};

    for my $hash (values %{$infos->{storages}}) {
        my $storage = _extractDiscBurning($hash);
        $storage->{TYPE} = 'Disk burning';
        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _extractDiscBurning {
    my ($hash) = @_;

    my $storage = {
        NAME         => $hash->{bsd_name} || $hash->{_name},
        MANUFACTURER => $hash->{manufacturer} ? getCanonicalManufacturer($hash->{manufacturer}) : getCanonicalManufacturer($hash->{_name}),
        INTERFACE    => $hash->{interconnect} eq 'SERIAL-ATA' ? "SATA" : "ATAPI",
        MODEL        => $hash->{_name},
        FIRMWARE     => $hash->{firmware}
    };

    if ($storage->{MODEL}) {
        $storage->{MODEL} =~ s/\s*$storage->{MANUFACTURER}\s*//i;
    }

    return $storage;
}

sub _getCardReaderStorages {
    my (%params) = @_;

    my $infos = getSystemProfilerInfos(
        type   => 'SPCardReaderDataType',
        format => 'xml',
        logger => $params{logger},
        file   => $params{file}
    );
    return unless $infos->{storages};

    my @storages = ();
    for my $hash (values %{$infos->{storages}}) {
        my $storage;
        if ($hash->{_name} eq 'spcardreader') {
            $storage = _extractCardReader($hash);
            $storage->{TYPE} = 'Card reader';
        } else {
            $storage = _extractSdCard($hash);
            $storage->{TYPE} = 'SD Card';
        }
        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _extractCardReader {
    my ($hash) = @_;

    my $storage = {
        NAME         => $hash->{bsd_name} || $hash->{_name},
        DESCRIPTION  => $hash->{_name},
        SERIAL       => $hash->{spcardreader_serialnumber},
        MODEL        => $hash->{_name},
        FIRMWARE     => $hash->{'spcardreader_revision-id'},
        MANUFACTURER => $hash->{'spcardreader_vendor-id'}
    };

    return $storage;
}

sub _extractSdCard {
    my ($hash) = @_;

    my $storage = {
        NAME         => $hash->{bsd_name} || $hash->{_name},
        DESCRIPTION  => $hash->{_name},
        DISKSIZE     => _extractDiskSize($hash)
    };

    return $storage;
}

sub _getUSBStorages {
    my (%params) = @_;

    my $infos = getSystemProfilerInfos(
        type   => 'SPUSBDataType',
        format => 'xml',
        logger => $params{logger},
        file   => $params{file}
    );
    return unless $infos->{storages};

    my @storages = ();
    for my $hash (values %{$infos->{storages}}) {
        unless ($hash->{bsn_name} && $hash->{bsd_name} =~ /^disk/) {
            next if $hash->{_name} eq 'Mass Storage Device';
            next if $hash->{_name} =~ /keyboard|controller|IR Receiver|built-in|hub|mouse|usb(?:\d+)?bus/i;
            next if ($hash->{'Built-in_Device'} && $hash->{'Built-in_Device'} eq 'Yes');
        }
        my $storage = _extractUSBStorage($hash);
        $storage->{TYPE} = 'Disk drive';
        $storage->{INTERFACE} = 'USB';
        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _extractUSBStorage {
    my ($hash) = @_;

    my $storage = {
        NAME         => $hash->{bsd_name} || $hash->{_name},
        DESCRIPTION  => $hash->{_name},
        SERIAL       => _extractValueInHashWithKeyPattern(qr/^(?:\w_)?serial_num$/, $hash),
        MODEL        => _extractValueInHashWithKeyPattern(qr/^(?:\w_)?device_model/, $hash) || $hash->{_name},
        FIRMWARE     => _extractValueInHashWithKeyPattern(qr/^(?:\w_)?bcd_device$/, $hash),
        MANUFACTURER => getCanonicalManufacturer(_extractValueInHashWithKeyPattern(qr/(?:\w+_)?manufacturer/, $hash)) || '',
        DISKSIZE     => _extractDiskSize($hash)
    };

    return $storage;
}

sub _extractDiskSize {
    my ($hash) = @_;

    return $hash->{size_in_bytes} ?
        getCanonicalSize($hash->{size_in_bytes} . ' bytes', 1024) :
            getCanonicalSize($hash->{size}, 1024);
}

sub _extractValueInHashWithKeyPattern {
    my ($pattern, $hash) = @_;

    my $value = '';
    my @keyMatches = grep { $_ =~ $pattern } keys %$hash;
    if (@keyMatches && (scalar @keyMatches) == 1) {
        $value = $hash->{$keyMatches[0]};
    }
    return $value;
}

sub _getFireWireStorages {
    my (%params) = @_;

    my $infos = getSystemProfilerInfos(
        type   => 'SPFireWireDataType',
        format => 'xml',
        logger => $params{logger},
        file   => $params{file}
    );
    return unless $infos->{storages};

    my @storages = ();
    for my $hash (values %{$infos->{storages}}) {
        my $storage = _extractFireWireStorage($hash);
        $storage->{TYPE} = 'Disk drive';
        $storage->{INTERFACE} = '1394';
        push @storages, _sanitizedHash($storage);
    }

    return @storages;
}

sub _extractFireWireStorage {
    my ($hash) = @_;

    my $storage = {
        NAME         => $hash->{bsd_name} || $hash->{_name},
        DESCRIPTION  => $hash->{_name},
        SERIAL       => _extractValueInHashWithKeyPattern(qr/^(?:\w_)?serial_num$/, $hash) || '',
        MODEL        => _extractValueInHashWithKeyPattern(qr/^(?:\w_)?product_id$/, $hash) || '',
        FIRMWARE     => _extractValueInHashWithKeyPattern(qr/^(?:\w_)?bcd_device$/, $hash) || '',
        MANUFACTURER => getCanonicalManufacturer(_extractValueInHashWithKeyPattern(qr/(?:\w+_)?manufacturer/, $hash)) || '',
        DISKSIZE     => _extractDiskSize($hash) || ''
    };

    return $storage;
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
