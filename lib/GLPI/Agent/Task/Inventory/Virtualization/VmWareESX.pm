package GLPI::Agent::Task::Inventory::Virtualization::VmWareESX;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('vmware-cmd');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $machine (_getMachines(
        command => 'vmware-cmd -l', logger => $logger
    )) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub _getMachines {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @machines;
    foreach my $line (@lines) {
        next unless has_file($line);

        my %info = _getMachineInfo(file => $line, logger => $params{logger});

        my $machine = {
            MEMORY    => $info{'memsize'},
            NAME      => $info{'displayName'},
            UUID      => $info{'uuid.bios'},
            SUBSYSTEM => "VmWareESX",
            VMTYPE    => "VmWare",
        };

        $machine->{STATUS} = getFirstMatch(
            command => "vmware-cmd '$line' getstate",
            logger  => $params{logger},
            pattern => qr/= (\w+)/
        ) || 'unknown';

        # correct uuid format
        $machine->{UUID} =~ s/\s+//g;      # delete space
        $machine->{UUID} =~ s/^(........)(....)(....)-(....)(.+)$/$1-$2-$3-$4-$5/; # add dashs

        push @machines, $machine;

    }

    return @machines;
}

sub _getMachineInfo {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my %info;
    foreach my $line (@lines) {
        next unless $line = /^(\S+)\s*=\s*(\S+.*)/;
        my $key = $1;
        my $value = $2;
        $value =~ s/(^"|"$)//g;
        $info{$key} = $value;
    }

    return %info;
}

1;
