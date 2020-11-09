package FusionInventory::Agent::Task::Inventory::Linux::Drives;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Unix;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{drive};
    return
        canRun('df') ||
        canRun('lshal');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $filesystem (_getFilesystems($logger)) {
        $inventory->addEntry(
            section => 'DRIVES',
            entry   => $filesystem
        );
    }
}

sub _getFilesystems {
    my ($logger) = @_;

    # get filesystems list
    my @filesystems =
        # exclude virtual file systems and overlay fs defined by docker
        grep { $_->{FILESYSTEM} !~ /^(tmpfs|devtmpfs|usbfs|proc|devpts|devshm|udev)$/ && $_->{VOLUMN} !~ /^overlay$/ }
        # get all file systems
        getFilesystemsFromDf(logger => $logger, command => 'df -P -T -k');

    # get additional informations
    if (canRun('blkid')) {
        # use blkid if available, as it is filesystem-independent
        foreach my $filesystem (@filesystems) {
            $filesystem->{SERIAL} = getFirstMatch(
                logger  => $logger,
                command => "blkid -w /dev/null $filesystem->{VOLUMN}",
                pattern => qr/\sUUID="(\S*)"\s/
            );
        }
    } else {
        # otherwise fallback to filesystem-dependant utilities
        my $has_dumpe2fs   = canRun('dumpe2fs');
        my $has_xfs_db     = canRun('xfs_db');
        my $has_dosfslabel = canRun('dosfslabel');
        my %months = (
            Jan => 1,
            Feb => 2,
            Mar => 3,
            Apr => 4,
            May => 5,
            Jun => 6,
            Jul => 7,
            Aug => 8,
            Sep => 9,
            Oct => 10,
            Nov => 11,
            Dec => 12,
        );

        foreach my $filesystem (@filesystems) {
            if ($filesystem->{FILESYSTEM} =~ /^ext(2|3|4|4dev)/ && $has_dumpe2fs) {
                my $handle = getFileHandle(
                    logger => $logger,
                    command => "dumpe2fs -h $filesystem->{VOLUMN}"
                );
                next unless $handle;
                while (my $line = <$handle>) {
                    if ($line =~ /Filesystem UUID:\s+(\S+)/) {
                        $filesystem->{SERIAL} = $1;
                    } elsif ($line =~ /Filesystem created:\s+\w+\s+(\w+)\s+(\d+)\s+([\d:]+)\s+(\d{4})$/) {
                        $filesystem->{CREATEDATE} = "$4/$months{$1}/$2 $3";
                    } elsif ($line =~ /Filesystem volume name:\s*(\S.*)/) {
                        $filesystem->{LABEL} = $1 unless $1 eq '<none>';
                    }
                }
                close $handle;
                next;
            }

            if ($filesystem->{FILESYSTEM} eq 'xfs' && $has_xfs_db) {
                $filesystem->{SERIAL} = getFirstMatch(
                    logger  => $logger,
                    command => "xfs_db -r -c uuid $filesystem->{VOLUMN}",
                    pattern => qr/^UUID =\s+(\S+)/
                );
                $filesystem->{LABEL} = getFirstMatch(
                    logger  => $logger,
                    command => "xfs_db -r -c label $filesystem->{VOLUMN}",
                    pattern => qr/^label =\s+"(\S+)"/
                );
                next;
            }

            if ($filesystem->{FILESYSTEM} eq 'vfat' && $has_dosfslabel) {
                $filesystem->{LABEL} = getFirstLine(
                    logger  => $logger,
                    command => "dosfslabel $filesystem->{VOLUMN}"
                );
                next;
            }
        }
    }

    # complete with hal if available
    if (canRun('lshal')) {
        my @hal_filesystems = _getFilesystemsFromHal();
        my %hal_filesystems = map { $_->{VOLUMN} => $_ } @hal_filesystems;

        foreach my $filesystem (@filesystems) {
            # retrieve hal informations for this drive
            my $hal_filesystem = $hal_filesystems{$filesystem->{VOLUMN}};
            next unless $hal_filesystem;

            # take hal information if it doesn't exist already
            foreach my $key (keys %$hal_filesystem) {
                $filesystem->{$key} = $hal_filesystem->{$key}
                    if !$filesystem->{$key};
            }
        }
    }

    my %devicemapper = ();
    my %cryptsetup = ();

    # complete with encryption status if available
    if (canRun('dmsetup') && canRun('cryptsetup')) {
        foreach my $filesystem (@filesystems) {
            # Find dmsetup uuid if available
            my $uuid = getFirstMatch(
                logger  => $logger,
                command => "dmsetup info $filesystem->{VOLUMN}",
                pattern => qr/^UUID\s*:\s*(.*)$/
            );
            next unless $uuid;

            # Find real devicemapper block name
            unless ($devicemapper{$uuid}) {
                foreach my $uuidfile (glob ("/sys/block/*/dm/uuid")) {
                    next unless getFirstLine(file => $uuidfile) eq $uuid;
                    ($devicemapper{$uuid}) = $uuidfile =~ m|^(/sys/block/[^/]+)|;
                    last;
                }
            }
            next unless $devicemapper{$uuid};

            # Lookup for crypto devicemapper slaves
            my @names = grep { defined($_) && length($_) } map {
                getFirstLine(file => $_)
            } glob ("$devicemapper{$uuid}/slaves/*/dm/name");

            # Finaly we may try on the device itself, see #825
            push @names, $filesystem->{VOLUMN};

            foreach my $name (@names) {
                # Check cryptsetup status for the found slave/device
                unless ($cryptsetup{$name}) {
                    my $handle = getFileHandle( command => "cryptsetup status $name" )
                        or next;
                    while (my $line = <$handle>) {
                        chomp $line;
                        next unless ($line =~ /^\s*(.*):\s*(.*)$/);
                        $cryptsetup{$name}->{uc($1)} = $2;
                    }
                    close $handle;
                }
                next unless $cryptsetup{$name};

                # Add cryptsetup status to filesystem
                $filesystem->{ENCRYPT_NAME}   = $cryptsetup{$name}->{TYPE};
                $filesystem->{ENCRYPT_STATUS} = 'Yes';
                $filesystem->{ENCRYPT_ALGO}   = $cryptsetup{$name}->{CIPHER};

                last;
            }
        }
    }

    return @filesystems;
}

sub _getFilesystemsFromHal {
    my $devices = _parseLshal(command => 'lshal');
    return @$devices;
}

sub _parseLshal {
    my $handle = getFileHandle(@_);
    return unless $handle;

    my $devices = [];
    my $device = {};

    while (my $line = <$handle>) {
        chomp $line;
        if ($line =~ m{^udi = '/org/freedesktop/Hal/devices/(volume|block).*}) {
            $device = {};
            next;
        }

        next unless defined $device;

        if ($line =~ /^$/) {
            if ($device->{ISVOLUME}) {
                delete($device->{ISVOLUME});
                push(@$devices, $device);
            }
            undef $device;
        } elsif ($line =~ /^\s+ block.device \s = \s '([^']+)'/x) {
            $device->{VOLUMN} = $1;
        } elsif ($line =~ /^\s+ volume.fstype \s = \s '([^']+)'/x) {
            $device->{FILESYSTEM} = $1;
        } elsif ($line =~ /^\s+ volume.label \s = \s '([^']+)'/x) {
            $device->{LABEL} = $1;
        } elsif ($line =~ /^\s+ volume.uuid \s = \s '([^']+)'/x) {
            $device->{SERIAL} = $1;
        } elsif ($line =~ /^\s+ storage.model \s = \s '([^']+)'/x) {
            $device->{TYPE} = $1;
         } elsif ($line =~ /^\s+ volume.size \s = \s (\S+)/x) {
            my $value = $1;
            $device->{TOTAL} = int($value/(1024*1024) + 0.5);
        } elsif ($line =~ /block.is_volume\s*=\s*true/i) {
            $device->{ISVOLUME} = 1;
        }
    }
    close $handle;

    return $devices;
}

1;
