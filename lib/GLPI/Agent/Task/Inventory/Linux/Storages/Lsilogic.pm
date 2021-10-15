package FusionInventory::Agent::Task::Inventory::Linux::Storages::Lsilogic;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Linux;

our $runMeIfTheseChecksFailed = ['FusionInventory::Agent::Task::Inventory::Linux::Storages'];

sub isEnabled {
    return canRun('mpt-status');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @devices = getDevicesFromUdev(logger => $logger);

    foreach my $device (@devices) {
        foreach my $disk (_getDiskFromMptStatus(
            name    => $device->{NAME},
            logger  => $logger,
            command => "mpt-status -n -i $device->{SCSI_UNID}"
        )) {
            # merge with smartctl info
            my $info = getInfoFromSmartctl(device => $disk->{device});
            foreach my $key (qw/SERIALNUMBER DESCRIPTION TYPE/) {
                $disk->{$key} = $info->{$key};
            }
            delete $disk->{device};
            $inventory->addEntry(section => 'STORAGES', entry => $disk);
        }
    }

}

sub _getDiskFromMptStatus {
    my (%params) = @_;

    my $handle = getFileHandle(%params);
    next unless $handle;

    my @disks;
    while (my $line = <$handle>) {
        next unless $line =~ /
            phys_id:(\d+) \s
            scsi_id:\d+ \s
            vendor:\S+ \s+
            product_id:(\S.+\S) \s+
            revision:(\S+) \s+
            size\(GB\):(\d+)
        /x;

        my $disk = {
            NAME         => $params{name},
            device       => "/dev/sg$1",
            MODEL        => $2,
            MANUFACTURER => getCanonicalManufacturer($2),
            FIRMWARE     => $3,
            DISKSIZE     => $4 * 1024
        };

        push @disks, $disk;
    }
    close $handle;

    return @disks;
}

1;
