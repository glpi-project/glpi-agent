package FusionInventory::Agent::Task::Inventory::AIX::Drives;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Unix;

use constant    category    => "drive";

sub isEnabled {
    return canRun('df');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # get filesystems
    my @filesystems =
        getFilesystemsFromDf(logger => $logger, command => 'df -P -k');

    my $types = _getFilesystemTypes(logger => $logger);

    # add filesystems to the inventory
    foreach my $filesystem (@filesystems) {
        $filesystem->{FILESYSTEM} = $types->{$filesystem->{TYPE}};

        $inventory->addEntry(
            section => 'DRIVES',
            entry   => $filesystem
        );
    }
}

sub _getFilesystemTypes {
    my (%params) = @_;

    my $handle = getFileHandle(
        command => 'lsfs -c',
        %params
    );
    return unless $handle;

    my $types;

    # skip headers
    my $line = <$handle>;

    foreach my $line (<$handle>) {
        my ($mountpoint, undef, $type) =  split(/:/, $line);
        $types->{$mountpoint} = $type;
    }
    close $handle;

    return $types;
}

1;
