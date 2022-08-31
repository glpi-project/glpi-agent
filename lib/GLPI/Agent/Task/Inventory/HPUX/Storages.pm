package GLPI::Agent::Task::Inventory::HPUX::Storages;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "storage";

sub isEnabled  {
    return
        canRun('ioscan');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $disk (_getDisks($logger)) {
        $inventory->addEntry(section => 'STORAGES', entry => $disk);
    }

    foreach my $tape (_getTapes($logger)) {
        $inventory->addEntry(section => 'STORAGES', entry => $tape);
    }
}

sub _getDisks {
    my ($logger) = @_;

    my @disks;
    foreach my $device (
        _parseIoscan(command => 'ioscan -kFnC disk', logger => $logger)
    ) {
        # skip alternate links
        next if getFirstMatch(
            command => "pvdisplay $device->{NAME}",
            pattern => qr/$device->{NAME}\.+lternate/
        );

        my @lines = getAllLines(
            command => "diskinfo -v $device->{NAME}",
            logger  => $logger
        );
        foreach my $line (@lines) {
            if ($line =~ /^\s+size:\s+(\S+)/) {
                $device->{DISKSIZE} = int($1/1024);
            }
            if ($line =~ /^\s+rev level:\s+(\S+)/) {
                $device->{FIRMWARE} = $1;
            }
        }

        $device->{TYPE} = 'disk';
        push @disks, $device;
    }

    return @disks;
}

sub _getTapes {
    my ($logger) = @_;

    my @tapes;
    foreach my $device (
        _parseIoscan(command => 'ioscan -kFnC tape', logger => $logger)
    ) {
        $device->{TYPE} = 'tape';
        push @tapes, $device;
    }

    return @tapes;
}

sub _parseIoscan {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @devices;
    my ($description, $model, $manufacturer);
    foreach my $line (@lines) {
        if ($line =~ /^\s+(\S+)/ ) {
            my $device = $1;

            push @devices, {
                MANUFACTURER => $manufacturer,
                MODEL        => $model,
                NAME         => $device,
                DESCRIPTION  => $description,
            };
        } else {
            my @infos = split(/:/, $line);
            $description = $infos[0];
            ($manufacturer, $model) = $infos[17] =~ /^(\S+) \s+ (\S.*\S)$/x;
        }
    }

    return @devices;
}

1;
