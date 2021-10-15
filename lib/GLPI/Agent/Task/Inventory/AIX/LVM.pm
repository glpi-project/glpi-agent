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

    foreach my $volume (_getPhysicalVolumes($logger)) {
        $inventory->addEntry(section => 'PHYSICAL_VOLUMES', entry => $volume);
    }

    foreach my $group (_getVolumeGroups($logger)) {
        $inventory->addEntry(section => 'VOLUME_GROUPS', entry => $group);

        foreach my $volume (_getLogicalVolumes($logger, $group->{VG_NAME})) {
            $inventory->addEntry(section => 'LOGICAL_VOLUMES', entry => $volume);
        }
    }
}

sub _getLogicalVolumes {
    my ($logger, $group) = @_;

    my $handle = getFileHandle(
        command => "lsvg -l $group",
        logger  => $logger
    );
    return unless $handle;

    # skip headers
    my $line;
    $line = <$handle>;
    $line = <$handle>;

    # no logical volume if there is only one line of output
    return unless $line;

    my @volumes;

    while (my $line = <$handle>) {
        chomp $line;
        my ($name) = split(/\s+/, $line);
        push @volumes, _getLogicalVolume(logger => $logger, name => $name);
    }

    close $handle;

    return @volumes;
}

sub _getLogicalVolume {
    my (%params) = @_;

    my $command = $params{name} ? "lslv $params{name}" : undef;
    my $handle = getFileHandle(command => $command, %params);
    return unless $handle;

    my $volume = {
        LV_NAME => $params{name}
    };

    my $size;
    while (my $line = <$handle>) {
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
    close $handle;

    $volume->{SIZE} = $volume->{SEG_COUNT} * $size;

    return $volume;
}

sub _getPhysicalVolumes {
    my ($logger) = @_;

    my $handle = getFileHandle(
        command => 'lspv',
        logger  => $logger
    );
    return unless $handle;

    my @volumes;

    while (my $line = <$handle>) {
        chomp $line;
        my ($name) = split(/\s+/, $line);
        push @volumes, _getPhysicalVolume(logger => $logger, name => $name);
    }
    close $handle;

    return @volumes;
}

sub _getPhysicalVolume {
    my (%params) = @_;

    my $command = $params{name} ? "lspv $params{name}" : undef;
    my $handle = getFileHandle(command => $command, %params);
    return unless $handle;

    my $volume = {
        DEVICE  => "/dev/$params{name}"
    };

    my ($free, $total);
    while (my $line = <$handle>) {
        chomp $line;

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
    close $handle;

    if (defined $volume->{PE_SIZE}) {
        $volume->{SIZE} = $total * $volume->{PE_SIZE} if defined $total;
        $volume->{FREE} = $free * $volume->{PE_SIZE} if defined $free;
    }
    $volume->{PV_PE_COUNT} = $total if defined $total;

    return $volume;
}

sub _getVolumeGroups {
    my ($logger) = @_;

    my $handle = getFileHandle(
        command => 'lsvg',
        logger  => $logger
    );
    return unless $handle;

    my @groups;

    while (my $line = <$handle>) {
        chomp $line;
        push @groups, _getVolumeGroup(logger => $logger, name => $line);
    }
    close $handle;

    return @groups;
}

sub _getVolumeGroup {
    my (%params) = @_;

    my $command = $params{name} ? "lsvg $params{name}" : undef;
    my $handle = getFileHandle(command => $command, %params);
    return unless $handle;

    my $group = {
        VG_NAME => $params{name}
    };

    while (my $line = <$handle>) {
        chomp $line;

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
    close $handle;

    return $group;
}

1;
