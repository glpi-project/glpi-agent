package GLPI::Agent::Task::Inventory::Linux::LVM;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

use constant    category    => "lvm";

sub isEnabled {
    return canRun('lvs');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $volume (_getLogicalVolumes(logger => $logger)) {
        $inventory->addEntry(section => 'LOGICAL_VOLUMES', entry => $volume);
    }

    foreach my $volume (_getPhysicalVolumes(logger => $logger)) {
        $inventory->addEntry(section => 'PHYSICAL_VOLUMES', entry => $volume);
    }

    foreach my $group (_getVolumeGroups(logger => $logger)) {
        $inventory->addEntry(section => 'VOLUME_GROUPS', entry => $group);
    }
}

sub _getLogicalVolumes {
    my (%params) = (
        command => 'lvs -a --noheading --nosuffix --units M -o lv_name,vg_uuid,lv_attr,lv_size,lv_uuid,seg_count',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @volumes;
    foreach my $line (@lines) {
        my @infos = split(/\s+/, $line);

        push @volumes, {
            LV_NAME   => $infos[1],
            VG_UUID   => $infos[2],
            ATTR      => $infos[3],
            SIZE      => int($infos[4]||0),
            LV_UUID   => $infos[5],
            SEG_COUNT => $infos[6],
        }
    }

    return @volumes;
}

sub _getPhysicalVolumes {
    my (%params) = (
        command => 'pvs --noheading --nosuffix --units M -o pv_name,pv_fmt,pv_attr,pv_size,pv_free,pv_uuid,pv_pe_count,vg_uuid',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @volumes;
    foreach my $line (@lines) {
        my @infos = split(/\s+/, $line);

        my $pe_size;
        if ($infos[7] && $infos[7]>0) {
            $pe_size = int($infos[4] / $infos[7]);
        }

        push @volumes, {
            DEVICE      => $infos[1],
            FORMAT      => $infos[2],
            ATTR        => $infos[3],
            SIZE        => int($infos[4]||0),
            FREE        => int($infos[5]||0),
            PV_UUID     => $infos[6],
            PV_PE_COUNT => $infos[7],
            PE_SIZE     => $pe_size,
            VG_UUID     => $infos[8]
        };
    }

    return @volumes;
}

sub _getVolumeGroups {
    my (%params) = (
        command => 'vgs --noheading --nosuffix --units M -o vg_name,pv_count,lv_count,vg_attr,vg_size,vg_free,vg_uuid,vg_extent_size',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @groups;
    foreach my $line (@lines) {
        my @infos = split(/\s+/, $line);

        push @groups, {
            VG_NAME        => $infos[1],
            PV_COUNT       => $infos[2],
            LV_COUNT       => $infos[3],
            ATTR           => $infos[4],
            SIZE           => int($infos[5]||0),
            FREE           => int($infos[6]||0),
            VG_UUID        => $infos[7],
            VG_EXTENT_SIZE => $infos[8],
        };
    }

    return @groups;
}

1;
