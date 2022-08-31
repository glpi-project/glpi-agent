package GLPI::Agent::Task::Inventory::Linux::Storages::Megacli;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

our $runMeIfTheseChecksFailed = ['GLPI::Agent::Task::Inventory::Linux::Storages::MegacliWithSmartctl'];

sub isEnabled {
    return canRun('megacli');
}

# The module gets disk data from `megacli -PDlist` and `megacli -ShowSummary`.
# `PDlist` provides s/n and model in a single 'Inquiry Data' string, and
# `ShowSummary` helps unpacking this data.
sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $count = getFirstMatch(
        command => "megacli -adpCount",
        pattern => qr/Controller Count: (\d+)/
    );
    return unless $count;

    for (my $adp = 0; $adp < $count; $adp++) {
        my $adapter  = _getAdpEnclosure( adp => $adp );
        my $summary  = _getSummary( adp => $adp );
        my $pdlist   = _getPDlist( adp => $adp );
        my $storages = _getStorages($adapter, $pdlist, $summary);
        foreach my $storage (values(%{$storages})) {
            $inventory->addEntry(
                section => 'STORAGES',
                entry   => $storage,
            );
        }
    }
}

sub _getStorages {
    my ($adp, $pdlist, $summary) = @_;

    my $storages;

    while (my ($pd_id, $pd) = each %{$pdlist}) {
        my ($model, $vendor);

        # Raw Size: 232.885 GB [0x1d1c5970 Sectors]
        my ($size) = ($pd->{'Raw Size'} =~ /^(.+)\s\[/);
        $size = getCanonicalSize($size);
        my $firmware = $pd->{'Device Firmware Level'};

        my $storage = {
            TYPE         => 'disk',
            FIRMWARE     => $firmware,
            DESCRIPTION  => $pd->{'PD Type'},
            DISKSIZE     => $size,
        };

        # Lookup the disk info in 'ShowSummary'
        my $sum = first {
            ((exists $_->{encl_id}  && $adp->{$_->{encl_id}} == $pd->{'Enclosure Device ID'} &&
              exists $_->{encl_pos} && $_->{encl_pos}        eq $pd->{'Enclosure position'})
                or
             (!exists $_->{encl_id} && !exists $_->{encl_pos}))
                &&
            $_->{slot} == $pd->{'Slot Number'}
        } values(%{$summary});

        if ($sum) {
            # 'HUC101212CSS'  <-- note it is incomplete
            $model = $sum->{'Product Id'};

            # 'HGST    HUC101212CSS600 U5E0KZGLG2HE'
            my $serial = $pd->{'Inquiry Data'};
            $serial =~ s/$firmware//;        # remove firmware part

            if ($sum->{'Vendor Id'} ne 'ATA') {
                $vendor = $sum->{'Vendor Id'};
                $serial =~ s/$vendor//;      # remove vendor part
            }

            $serial =~ s/$model\S*//;        # remove model part
            $serial =~ s/\s//g;              # remove remaining spaces
            $storage->{SERIALNUMBER} = $serial;

            # Restore complete model name:
            # HUC101212CSS --> HUC101212CSS600
            if ($pd->{'Inquiry Data'} =~ /($model(?:\S*))/) {
                $model = $1;
                $model =~ s/^\s+//;
                $model =~ s/\s+$//;
            }
        }

        # When Product ID ($model) looks like 'INTEL SSDSC2CW24'
        if ($model =~ /^(\S+)\s+(\S+)$/) {
            $vendor = $1;        # 'INTEL'
            $model  = $2;        # 'SSDSC2CW24'
        }

        $storage->{NAME}  = $model;
        $storage->{MODEL} = $model;
        $storage->{MANUFACTURER} = defined $vendor ?
            getCanonicalManufacturer($vendor) :
            getCanonicalManufacturer($model);

        $storages->{$pd_id} = $storage;
    }

    return $storages;
}

sub _getAdpEnclosure {
    my (%params) = @_;

    $params{command} = "megacli -EncInfo -a$params{adp} -NoLog" if defined($params{adp});
    my @lines = getAllLines(%params)
        or return;

    my %enclosure;
    my $encl_id;

    foreach my $line (@lines) {
        if ($line =~ /Enclosure (\d+):/) {
            $encl_id = $1;
        }

        if ($line =~ /Device ID\s+:\s+(\d+)/) {
            $enclosure{$encl_id} = $1;
        }
    }

    return \%enclosure;
}

sub _getSummary {
    my (%params) = @_;

    $params{command} = "megacli -ShowSummary -a$params{adp} -NoLog" if defined($params{adp});
    my @lines = getAllLines(%params)
        or return;

    # fast forward to relevant section
    while (1) {
        my $line = shift @lines;
        last unless defined($line);
        last if $line =~ /^\s+PD\s+$/;
    }

    my %drive;
    my $n = -1;
    foreach my $line (@lines) {
        # end of relevant section
        last if $line =~ /^Storage$/;

        $n++ if $line =~ /Connector\s*:/;

        if ($line =~ /Connector\s*:\s*(\d+)(?:<Internal>)?<Encl Pos (\d+) >: Slot (\d+)/) {
            $drive{$n} = {
                encl_id  => $1,
                encl_pos => $2,
                slot     => $3,
            };
            $drive{$n}->{'encl_id'} += 0;  # drop leading zeroes
        } elsif ($line =~ /Connector\s*:\s*(?:\d+)(?:<Internal>):\s*Slot (\d+)/) {
            $drive{$n} = {
                slot     => $1,
            };
        } elsif ($line =~ /^\s*(.+\S)\s*:\s*(.+\S)/) {
            $drive{$n}->{$1} = $2;
        }
    }

    # delete non-disks
    while (my ($k, $d) = each %drive) {
        delete $drive{$k} if (!defined $d->{'slot'} or
            exists $d->{'Product Id'} and $d->{'Product Id'} eq 'SAS2 EXP BP');
    }

    return \%drive;
}

sub _getPDlist {
    my (%params) = @_;

    $params{command} = "megacli -PDlist -a$params{adp} -NoLog" if defined($params{adp});
    my @lines = getAllLines(%params)
        or return;

    my %pdlist;
    my $n = 0;
    foreach my $line (@lines) {
        next unless $line =~ /^([^:]+)\s*:\s*(.*\S)/;
        my $key = $1;
        my $val = $2;
        $n++ if $key =~ /Enclosure Device ID/;
        $pdlist{$n}->{$key} = $val;
    }

    return \%pdlist;
}

1;
