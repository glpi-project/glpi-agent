package GLPI::Agent::Task::Inventory::BSD::Drives;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;

use constant    category    => "drive";

sub isEnabled {
    return canRun('df');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $zpool = canRun('zpool');

    # Check we can run geli command to lookup encrypted fs
    my ($geli);
    if (canRun('geom')) {
        $geli = _getGeliList(%params);
    }

    # get filesystem types
    my @types =
        grep { ! /^(?:fdesc|devfs|procfs|linprocfs|linsysfs|tmpfs|fdescfs)$/ }
        getFilesystemsTypesFromMount(logger => $logger);

    # get filesystem for each type
    my @filesystems;
    foreach my $type (@types) {
        my $foundfs = getFilesystemsFromDf(
            logger  => $logger,
            command => "df -P -k -t $type",
            type    => $type
        );

        # Check for geli encryption
        if ($geli) {
            foreach my $fs (@{$foundfs}) {
                my $encrypted;
                if ($type eq 'zfs' && $zpool) {
                    my $status = _getZpoolStatus(
                        volumn  => $fs->{VOLUMN},
                        %params
                    );
                    ($encrypted) = grep { /.eli$/ } keys(%{$status->{config}});
                } else {
                    ($encrypted) = $fs->{VOLUMN} =~ m|/([^/]+.eli)$|;
                }
                if ($encrypted && $geli->{$encrypted}) {
                    $fs->{ENCRYPT_NAME}   = "geli";
                    $fs->{ENCRYPT_STATUS} = $geli->{$encrypted}->{state} =~ /^ACTIVE$/i ? 'Yes' : 'No';
                    $fs->{ENCRYPT_ALGO}   = $geli->{$encrypted}->{algo};
                    $fs->{ENCRYPT_TYPE}   = $geli->{$encrypted}->{type};
                }
            }
        }

        push @filesystems, @{$foundfs};
    }

    # add filesystems to the inventory
    foreach my $filesystem (@filesystems) {
        $inventory->addEntry(
            section => 'DRIVES',
            entry   => $filesystem
        );
    }
}

my %zpool_status_cache = ();
sub _getZpoolStatus {
    my (%params) = @_;

    my $volumn  = $params{volumn}
        or return;

    my ($pool) = $volumn =~ m|^([^/]+)|;

    return $zpool_status_cache{$pool}
        if $zpool_status_cache{$pool};

    my @lines = getAllLines(
        command => "zpool status $pool",
        %params
    );

    my $status = {};
    foreach my $line (@lines) {
        next unless $line;
        if ($line =~ /^\s*(\w+)\s*:\s*(\w.*)$/) {
            $status->{$1} = $2;
        } elsif ($line =~ /^\s*config\s*:/) {
            $status->{config} = {};
        } elsif ($status->{config} && $line =~ /^\s*(\S+)\s+(\w+)\s+\w+\s+\w+\s+\w+/) {
            next if $1 eq "NAME";
            $status->{config}->{$1} = $2;
        }
    }

    # Cache zpool status
    $zpool_status_cache{$pool} = $status;

    return $status;
}

sub _getGeliList {
    my (%params) = @_;

    my $geli;

    my @status = getAllLines(
        command => "geom eli status -s",
        %params
    );

    foreach my $status (@status) {
        next unless $status =~ /^(\S+)\s/;

        my $volumn = $1;

        my @lines = getAllLines(
            command => "geom eli list $volumn",
            %params
        );
        foreach my $line (@lines) {
            next unless $line;
            if ($line =~ /^State:\s*(\S+)$/) {
                $geli->{$volumn}->{state} = $1;
            } elsif ($line =~ /^EncryptionAlgorithm:\s*(\S+)$/) {
                $geli->{$volumn}->{algo} = $1;
            } elsif ($line =~ /^KeyLength:\s*(\S+)$/) {
                $geli->{$volumn}->{keysize} = $1;
            } elsif ($line =~ /^Crypto:\s*(\S+)$/) {
                $geli->{$volumn}->{type} = $1;
            }
        }

        # Fix algo with keysize
        if ($geli->{$volumn}->{algo} && $geli->{$volumn}->{keysize}) {
            $geli->{$volumn}->{algo} = $geli->{$volumn}->{algo}."-".$geli->{$volumn}->{keysize};
            delete $geli->{$volumn}->{keysize};
        }
    }

    return $geli;
}

1;
