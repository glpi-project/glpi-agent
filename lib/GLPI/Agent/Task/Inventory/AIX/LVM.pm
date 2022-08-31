package GLPI::Agent::Task::Inventory::AIX::LVM;

use GLPI::Agent::Tools;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use constant    category    => "lvm";

sub isEnabled {
    return canRun('lspv');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $volume (_getPhysicalVolumes(
        command => 'lsvp',
        logger  => $logger
    )) {
        $inventory->addEntry(section => 'PHYSICAL_VOLUMES', entry => $volume);
    }

    foreach my $group (_getVolumeGroups(
        command => 'lsvg',
        logger  => $logger
    )) {
        $inventory->addEntry(section => 'VOLUME_GROUPS', entry => $group);

        foreach my $volume (_getLogicalVolumes(
            command => "lsvg -l $group->{VG_NAME}",
            logger  => $logger
        )) {
            $inventory->addEntry(section => 'LOGICAL_VOLUMES', entry => $volume);
        }
    }
}

sub _getLogicalVolumes {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    # skip headers
    shift @lines;

    # no logical volume if there is only one line of output
    return unless shift @lines;

    my @volumes;

    foreach my $line (@lines) {
        my ($name) = split(/\s+/, $line);
        push @volumes, _getLogicalVolume(logger => $params{logger}, name => $name);
    }

    return @volumes;
}

sub _getLogicalVolume {
    my (%params) = @_;

    $params{command} = "lslv $params{name}" if $params{name};
    my @lines = getAllLines(%params)
        or return;

    my $volume = {
        LV_NAME => $params{name}
    };

    my $size;
    foreach my $line (@lines) {
        if ($line =~ /PP SIZE:\s+(\d+)/) {
            $size = $1;
        }
        if ($line =~ /^LV IDENTIFIER:\s+(\S+)/) {
            $volume->{LV_UUID} = $1;
        }
        if ($line =~ /^LPs:\s+(\S+)/) {
            $volume->{SEG_COUNT} = $1;
        }
        if ($line =~ /^TYPE:\s+(\S+)/) {
            $volume->{ATTR} = "Type $1";
        }
    }

    $volume->{SIZE} = $volume->{SEG_COUNT} * $size;

    return $volume;
}

sub _getPhysicalVolumes {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @volumes;

    foreach my $line (@lines) {
        my ($name) = split(/\s+/, $line);
        push @volumes, _getPhysicalVolume(
            logger  => $params{logger},
            name    => $name
        );
    }

    return @volumes;
}

sub _getPhysicalVolume {
    my (%params) = @_;

    $params{command} = "lspv $params{name}" if $params{name};
    my @lines = getAllLines(%params)
        or return;

    my $volume = {
        DEVICE  => "/dev/$params{name}"
    };

    my ($free, $total);
    foreach my $line (@lines) {
        if ($line =~ /PHYSICAL VOLUME:\s+(\S+)/) {
            $volume->{FORMAT} = "AIX PV";
        }
        if ($line =~ /FREE PPs:\s+(\d+)/) {
            $free = $1;
        }
        if ($line =~ /TOTAL PPs:\s+(\d+)/) {
            $total = $1;
        }
        if ($line =~ /VOLUME GROUP:\s+(\S+)/) {
            $volume->{ATTR} = "VG $1";
        }
        if ($line =~ /PP SIZE:\s+(\d+)/) {
            $volume->{PE_SIZE} = $1;
        }
        if ($line =~ /PV IDENTIFIER:\s+(\S+)/) {
            $volume->{PV_UUID} = $1;
        }
    }

    if (defined $volume->{PE_SIZE}) {
        $volume->{SIZE} = $total * $volume->{PE_SIZE} if defined $total;
        $volume->{FREE} = $free * $volume->{PE_SIZE} if defined $free;
    }
    $volume->{PV_PE_COUNT} = $total if defined $total;

    return $volume;
}

sub _getVolumeGroups {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @groups;

    foreach my $line (@lines) {
        push @groups, _getVolumeGroup(
            logger  => $params{logger},
            name    => $line
        );
    }

    return @groups;
}

sub _getVolumeGroup {
    my (%params) = @_;

    $params{command} = "lsvg $params{name}" if $params{name};
    my @lines = getAllLines(%params)
        or return;

    my $group = {
        VG_NAME => $params{name}
    };

    foreach my $line (@lines) {
        if ($line =~ /TOTAL PPs:\s+(\d+)/) {
            $group->{SIZE} = $1;
        }
        if ($line =~ /FREE PPs:\s+(\d+)/) {
            $group->{FREE} = $1;
        }
        if ($line =~ /VG IDENTIFIER:\s+(\S+)/) {
            $group->{VG_UUID} = $1;
        }
        if ($line =~ /PP SIZE:\s+(\d+)/) {
            $group->{VG_EXTENT_SIZE} = $1;
        }
        if ($line =~ /LVs:\s+(\d+)/) {
            $group->{LV_COUNT} = $1;
        }
        if ($line =~/ACTIVE PVs:\s+(\d+)/) {
            $group->{PV_COUNT} = $1;
        }
    }

    return $group;
}

1;
