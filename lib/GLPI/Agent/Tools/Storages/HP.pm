package GLPI::Agent::Tools::Storages::HP;

use strict;
use warnings;

use parent 'Exporter';

use parent 'GLPI::Agent::Task::Inventory::Module';

our @EXPORT = qw(
    HpInventory
);

use GLPI::Agent::Tools;

# This speeds up hpacucli startup by skipping non-local (iSCSI, Fibre) storages.
# See https://support.hpe.com/hpsc/doc/public/display?docId=emr_na-c03696601
$ENV{INFOMGR_BYPASS_NONSA} = "1";

sub HpInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $path      = $params{path};

    foreach my $slot (_getSlots(path => $path)) {
        foreach my $drive (_getDrives(path => $path, slot => $slot)) {

            $inventory->addEntry(
                section => 'STORAGES',
                entry   => _getStorage(
                    path => $path, slot => $slot, drive => $drive
                )
            );
        }
    }
}

sub _getSlots {
    my %params = @_;

    $params{command} = "$params{path} ctrl all show" if $params{path};
    my @lines = getAllLines(%params)
        or return;

    my @slots;
    foreach my $line (@lines) {
        next unless $line =~ /Slot (\d+)/;
        push @slots, $1;
    }

    return @slots;
}

sub _getDrives {
    my %params = @_;

    $params{command} = "$params{path} ctrl slot=$params{slot} pd all show"
        if $params{path} && defined($params{slot});

    my @lines = getAllLines(%params)
        or return;

    my @drives;
    foreach my $line (@lines) {
        next unless $line =~ /physicaldrive (\S+)/;
        push @drives, $1;
    }

    return @drives;
}

sub _getStorage {
    my %params = @_;

    $params{command} = "$params{path} ctrl slot=$params{slot} pd $params{drive} show"
        if $params{path} && defined($params{slot}) && defined($params{drive});

    my @lines = getAllLines(%params)
        or return;

    my %data;
    foreach my $line (@lines) {
        next unless $line =~ /^\s*(\S[^:]+):\s+(.+)$/x;
        $data{$1} = $2;
        $data{$1} =~ s/\s+$//;
    }

    my $storage = {
        DESCRIPTION  => $data{'Interface Type'},
        SERIALNUMBER => $data{'Serial Number'},
        FIRMWARE     => $data{'Firmware Revision'}
    };

    # Possible models:
    # HP      EG0300FBDBR
    # ATA     WDC WD740ADFD-00
    my $model = $data{'Model'};
    $model =~ s/^ATA\s+//;
    $model =~ s/\s+/ /;
    $storage->{NAME} = $model;

    if ($model =~ /^(\S+)\s+(\S+)$/) {
        $storage->{MANUFACTURER} = getCanonicalManufacturer($1);
        $storage->{MODEL}  = $2;
    } else {
        $storage->{MANUFACTURER} = getCanonicalManufacturer($model);
        $storage->{MODEL} = $model;
    }

    $storage->{DISKSIZE} = getCanonicalSize($data{'Size'});

    $storage->{TYPE} = $data{'Drive Type'} eq 'Data Drive' ?
        'disk' : $data{'Drive Type'};

    return $storage;
}

1;
