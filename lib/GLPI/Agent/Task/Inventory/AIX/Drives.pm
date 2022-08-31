package GLPI::Agent::Task::Inventory::AIX::Drives;

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

    # get filesystems
    my @filesystems =
        getFilesystemsFromDf(logger => $logger, command => 'df -P -k');

    my $types = _getFilesystemTypes(
        command => 'lsfs -c',
        logger  => $logger
    );

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

    my @lines = getAllLines(%params)
        or return;

    my $types;

    # skip headers
    shift @lines;

    foreach my $line (@lines) {
        my ($mountpoint, undef, $type) =  split(/:/, $line);
        $types->{$mountpoint} = $type;
    }

    return $types;
}

1;
