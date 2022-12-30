package GLPI::Agent::Task::Inventory::Linux::Storages::Adaptec;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Linux;

our $runMeIfTheseChecksFailed = ['GLPI::Agent::Task::Inventory::Linux::Storages'];

sub isEnabled {
    return canRead('/proc/scsi/scsi');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @devices = getDevicesFromUdev(logger => $logger);

    foreach my $device (@devices) {
        next unless $device->{MANUFACTURER};
        next unless
            $device->{MANUFACTURER} eq 'Adaptec' ||
            $device->{MANUFACTURER} eq 'Sun'     ||
            $device->{MANUFACTURER} eq 'ServeRA';

        foreach my $disk (_getDisksFromProc(
                controller => 'scsi' . $device->{SCSI_COID},
                name       => $device->{NAME},
                logger     => $logger
        )) {
            # merge with smartctl info
            my $info = getInfoFromSmartctl(device => $disk->{device});
            next unless $info->{TYPE} =~ /disk/i;
            foreach my $key (qw/SERIALNUMBER DESCRIPTION TYPE DISKSIZE MANUFACTURER/) {
                $disk->{$key} = $info->{$key};
            }
            delete $disk->{device};
            $inventory->addEntry(section => 'STORAGES', entry => $disk);
        }
    }
}

sub _getDisksFromProc {
    my (%params) = (
        file => '/proc/scsi/scsi',
        @_
    );

    return unless $params{controller};

    my @lines = getAllLines(%params)
        or return;

    my @disks;
    my $disk;

    my $count = -1;
    foreach my $line (@lines) {
        if ($line =~ /^Host: (\w+)/) {
            $count++;
            if ($1 eq $params{controller}) {
                # that's the controller we're looking for
                $disk = {
                    NAME        => $params{name},
                };
            } else {
                # that's another controller
                undef $disk;
            }
        }

        if ($line =~ /Model: \s (\S.+\S) \s+ Rev: \s (\S+)/x) {
            next unless $disk;
            $disk->{MODEL}    = $1;
            $disk->{FIRMWARE} = $2;

            # that's the controller itself, not a disk
            next if $disk->{MODEL} =~ /raid|virtual/i;

            $disk->{MANUFACTURER} = getCanonicalManufacturer(
                $disk->{MODEL}
            );
            $disk->{device} = "/dev/sg$count";

            push @disks, $disk;
        }
    }

    return @disks;
}

1;
