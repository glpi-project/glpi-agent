package GLPI::Agent::Task::Inventory::Generic::Storages::HpWithSmartctl;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Linux;

# This speeds up hpacucli startup by skipping non-local (iSCSI, Fibre) storages.
# See https://support.hpe.com/hpsc/doc/public/display?docId=emr_na-c03696601
$ENV{INFOMGR_BYPASS_NONSA} = "1";

sub isEnabled {
    return canRun('hpacucli')
        && canRun('smartctl')
        # TODO: find a generic solution
        && Glob("/sys/class/scsi_generic/sg*/device/vpd_pg80");
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $adp = _getData(%params);

    for my $data (values %$adp) {
        next unless $data->{drives_total} && $data->{device};

        for (my $i = 0; $i < $data->{drives_total}; $i++) {
            my $storage = getInfoFromSmartctl(
                device => '/dev/' . $data->{device},
                extra  => '-d cciss,' . $i,
                %params
            );

            $inventory->addEntry(
                section => 'STORAGES',
                entry   => $storage,
            );
        }
    }
}

sub _getData {
    my %params = (
        command => 'hpacucli ctrl all show config',
        @_
    );

    my $data = {};
    my $slot = -1;

    foreach my $line (getAllLines(%params)) {
        if ($line =~ /^Smart Array \w+ in Slot (\d+)\s+(?:\(Embedded\)\s+)?\(sn: (\w+)\)/) {
            $data->{$1} = {
                serial       => $2,
                drives_total => 0,
            };
            $slot = $1;
        } elsif ($line =~ /^\s+physicaldrive\s/ && $line !~ /Failed/) {
            $data->{$slot}->{drives_total}++;
        }
    }

    _adpToDevice($data);

    return $data;
}

# Linux case
sub _adpToDevice {
    my ($adp) = @_;

    foreach my $file (Glob("/sys/class/scsi_generic/sg*/device/vpd_pg80")) {
        my $serial = getFirstMatch(
            file    => $file,
            pattern => qr/(\w+)/
        );
        next unless $serial;

        my $slot = first { $adp->{$_}->{serial} eq $serial } keys %$adp;
        next unless defined $slot;
        ($adp->{$slot}->{device}) = $file =~ /\/(sg\d+)\// or next;
    }
}

1;
