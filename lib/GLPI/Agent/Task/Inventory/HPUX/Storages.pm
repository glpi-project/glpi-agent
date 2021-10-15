package FusionInventory::Agent::Task::Inventory::HPUX::Storages;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

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

        my $handle = getFileHandle(
            command => "diskinfo -v $device->{NAME}",
            logger  => $logger
        );
        while (my $line = <$handle>) {
            if ($line =~ /^\s+size:\s+(\S+)/) {
                $device->{DISKSIZE} = int($1/1024);
            }
            if ($line =~ /^\s+rev level:\s+(\S+)/) {
                $device->{FIRMWARE} = $1;
            }
        }
        close $handle;

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
    my $handle = getFileHandle(@_);
    return unless $handle;

    my @devices;
    my ($description, $model, $manufacturer);
    while (my $line = <$handle>) {
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
    close $handle;

    return @devices;
}

1;
