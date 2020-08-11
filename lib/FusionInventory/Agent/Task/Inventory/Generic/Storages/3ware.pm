package FusionInventory::Agent::Task::Inventory::Generic::Storages::3ware;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Linux;

use English qw(-no_match_vars);

# Tested on 2.6.* kernels
#
# Cards tested :
#
# 8006-2LP
# 9500S-4LP
# 9550SXU-4LP
# 9550SXU-8LP
# 9650SE-2LP
# 9650SE-4LPML
# 9650SE-8LPML
#
# AMCC/3ware CLI (version 2.00.0X.XXX)

sub isEnabled {
    return canRun('tw_cli');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @devices;

    foreach my $card (_getCards()) {
        foreach my $unit (_getUnits($card)) {

            # Try do get unit's serial in order to compare it to what was found
            # in udev db.
            # Works only on newer cards.
            # Allow us to associate a node to a drive : sda -> WD-WMANS1648590
            my $sn = getFirstMatch(
                logger => $logger,
                command => "tw_cli info $card->{id} $unit->{id} serial",
                pattern => qr/serial number\s=\s(\w+)/
            );

            foreach my $port (_getPorts($card, $unit)) {
                # Finally, getting drives' values.
                my $storage = _getStorage($card, $port);

                if (OSNAME eq 'Linux') {

                    @devices = getDevicesFromUdev(logger => $logger) unless @devices;

                    foreach my $device (@devices) {
# How does this work with multiple older cards
# where serial for units is not implemented ?
# Need to be tested on a system with multiple
# 3ware cards.
                        if (
                                $device->{SERIALNUMBER} eq 'AMCC_' . $sn ||
                                $device->{MODEL} eq 'Logical_Disk_' . $unit->{index}
                           ) {
                            $storage->{NAME} = $device->{NAME};
                        }
                    }
                }

                $inventory->addEntry(section => 'STORAGES', entry => $storage);
            }
        }
    }
}


sub _getCards {
    my ($file) = @_;

    my $handle = getFileHandle(
        file => $file,
        command => "tw_cli info"
    );
    return unless $handle;

    my @cards;
    while (my $line = <$handle>) {
        next unless $line =~ /^(c\d+)\s+([\w-]+)/;
        push @cards, { id => $1, model => $2 };
    }
    close $handle;

    return @cards;
}

sub _getUnits {
    my ($card, $file) = @_;

    my $handle = getFileHandle(
        file => $file,
        command => "tw_cli info $card->{id}"
    );
    return unless $handle;

    my @units;
    while (my $line = <$handle>) {
        next unless $line =~ /^(u(\d+))/;
        push @units, { id => $1, index => $2 };
    }
    close $handle;

    return @units;
}

sub _getPorts {
    my ($card, $unit, $file) = @_;

    my $handle = getFileHandle(
        file => $file,
        command => "tw_cli info $card->{id} $unit->{id}"
    );
    return unless $handle;

    my @ports;
    while (my $line = <$handle>) {
        next unless $line =~ /(p\d+)/;
        push @ports, { id => $1 };
    }
    close $handle;

    return @ports;
}

sub _getStorage {
    my ($card, $port, $file) = @_;

    my $handle = getFileHandle(
        file => $file,
        command =>
            "tw_cli info $card->{id} $port->{id} model serial capacity firmware"
    );
    return unless $handle;

    my $storage;
    while (my $line = <$handle>) {
        if ($line =~ /Model\s=\s(.*)/) {
            $storage->{MODEL} = $1;
        } elsif ($line =~ /Serial\s=\s(.*)/) {
            $storage->{SERIALNUMBER} = $1;
        } elsif ($line =~ /Capacity\s=\s(\S+)\sGB.*/) {
            $storage->{DISKSIZE} = 1024 * $1;
        } elsif ($line =~ /Firmware Version\s=\s(.*)/) {
            $storage->{FIRMWARE} = $1
        }
    }
    close $handle;

    $storage->{MANUFACTURER} = getCanonicalManufacturer(
        $storage->{MODEL}
    );
    $storage->{TYPE} = 'disk';

    # Getting description from card model, very basic
    # and unreliable
    # Assuming only IDE drives can be plugged in
    # 5xxx/6xxx cards and
    # SATA drives only to 7xxx/8xxx/9xxxx cards
    $storage->{DESCRIPTION} =
        $card->{model} =~ /^[56]/  ? 'IDE'  :
        $card->{model} =~ /^[789]/ ? 'SATA' :
        undef;

    return $storage;
}

1;
