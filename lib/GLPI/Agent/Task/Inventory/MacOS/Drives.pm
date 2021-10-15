package GLPI::Agent::Task::Inventory::MacOS::Drives;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;

use constant    category    => "drive";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # get filesystem types
    my @types =
        grep { ! /^(?:fdesc|devfs|procfs|linprocfs|linsysfs|tmpfs|fdescfs)$/ }
        getFilesystemsTypesFromMount(logger => $logger);

    # get filesystems for each type
    my @filesystems;
    foreach my $type (@types) {
        push @filesystems, getFilesystemsFromDf(
            logger  => $logger,
            command => "df -P -k -t $type",
            type    => $type,
        );
    }

    my %filesystems = map { $_->{VOLUMN} => $_ } @filesystems;

    foreach my $partition (_getPartitions()) {
        my $device = "/dev/$partition";

        my $info = _getPartitionInfo(partition => $partition);

        my $filesystem = $filesystems{$device};
        next unless $filesystem;

        if ($info->{'Total Size'} && $info->{'Total Size'} =~ /^([.\d]+ \s \S+)/x) {
            $filesystem->{TOTAL} = getCanonicalSize($1);
        }
        $filesystem->{SERIAL}     = $info->{'Volume UUID'} ||
                                    $info->{'UUID'};
        $filesystem->{FILESYSTEM} = $info->{'File System'} ||
                                    $info->{'Partition Type'};
        $filesystem->{LABEL}      = $info->{'Volume Name'};
    }

    # Check FileVault 2 support for root filesystem
    if (canRun('fdesetup')) {
        my $status = getFirstLine(command => 'fdesetup status');
        if ($status && $status =~ /FileVault is On/i) {
            $logger->debug("FileVault 2 is enabled");
            my ($rootfs) = grep { $_->{TYPE} eq '/' } values(%filesystems);
            if ($rootfs) {
                $rootfs->{ENCRYPT_STATUS} = 'Yes';
                $rootfs->{ENCRYPT_NAME}   = 'FileVault 2';
                $rootfs->{ENCRYPT_ALGO}   = 'XTS_AES_128';
            }
        } else {
            $logger->debug("FileVault 2 is disabled");
        }
    } else {
        $logger->debug("FileVault 2 is not supported");
    }

    # add filesystems to the inventory
    foreach my $key (keys %filesystems) {
        $inventory->addEntry(
            section => 'DRIVES',
            entry   => $filesystems{$key}
        );
    }
}

sub _getPartitions {
    my (%params) = @_;

    my $command = "diskutil list";
    my $handle = getFileHandle(command => $command, %params);
    return unless $handle;

    my @devices;
    while (my $line = <$handle>) {
        # partition identifiers look like disk0s1
        next unless $line =~ /(disk \d+ s \d+)$/x;
        push @devices, $1;
    }
    close $handle;

    return @devices;
}

sub _getPartitionInfo {
    my (%params) = @_;

    my $command = "diskutil info $params{partition}";
    my $handle = getFileHandle(command => $command, %params);
    return unless $handle;

    my $info;
    while (my $line = <$handle>) {
        next unless $line =~ /(\S[^:]+) : \s+ (\S.*\S)/x;
        $info->{$1} = $2;
    }
    close $handle;

    return $info;
}

1;
