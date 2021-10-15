package GLPI::Agent::Task::Inventory::Solaris::Drives;

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

    my $df_version = $params{df_version} ||
        getFirstLine(logger => $logger, command => "df --version");

    # get filesystems list

    # df --help is on STDERR on some system, so $line may be undef
    my $command = $df_version && $df_version =~ /GNU/ ? "df -P -k" : "df -k";

    my @filesystems =
        # exclude solaris 10 specific devices
        grep { $_->{VOLUMN} !~ /^\/(devices|platform)/ }
        # exclude cdrom mount
        grep { $_->{TYPE} !~ /cdrom/ }
        # get all file systems
        getFilesystemsFromDf(command => $command, %params);

    # get indexed list of filesystems types
    my %filesystems_types =
        map { /^(\S+) on \S+ type (\w+)/; $1 => $2 }
            $params{mount_res} ?
                getAllLines(logger => $logger, file => $params{mount_res}) :
                getAllLines(logger => $logger, command => '/usr/sbin/mount -v');

    # set filesystem type based on that information
    foreach my $filesystem (@filesystems) {
        if ($filesystem->{VOLUMN} eq 'swap') {
            $filesystem->{FILESYSTEM} = 'swap';
            next;
        }

        $filesystem->{FILESYSTEM} = $filesystems_types{$filesystem->{VOLUMN}};
    }

    # add filesystems to the inventory
    foreach my $filesystem (@filesystems) {
        # Skip if filesystem is lofs
        next if $filesystem->{FILESYSTEM} eq 'lofs';
        $inventory->addEntry(
            section => 'DRIVES',
            entry   => $filesystem
        );
    }
}
1;
