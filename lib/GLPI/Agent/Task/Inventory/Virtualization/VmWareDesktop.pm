package GLPI::Agent::Task::Inventory::Virtualization::VmWareDesktop;
#
# initial version: Walid Nouh
#

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Virtualization;

sub isEnabled {
    return
        canRun('/Library/Application Support/VMware Fusion/vmrun') ||
        canRun('vmrun');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $command = canRun('vmrun') ?
        'vmrun list' : "'/Library/Application Support/VMware Fusion/vmrun' list";

    foreach my $machine (_getMachines(
        command => $command, logger => $logger
    )) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub _getMachines {
   my (%params) = @_;

    my $handle = getFileHandle(%params);
    return unless $handle;

    # skip first line
    my $line = <$handle>;

    my @machines;
    while (my $line = <$handle>) {
        chomp $line;
        next unless has_file($line);

        my %info = _getMachineInfo(file => $line, logger => $params{logger});

        my $machine = {
            NAME      => $info{'displayName'},
            VCPU      => 1,
            UUID      => $info{'uuid.bios'},
            MEMORY    => $info{'memsize'},
            STATUS    => STATUS_RUNNING,
            SUBSYSTEM => "VmWare Fusion",
            VMTYPE    => "VmWare",
        };

        push @machines, $machine;
    }
    close $handle;

    return @machines;
}

sub _getMachineInfo {
    my $handle = getFileHandle(@_);
    return unless $handle;

    my %info;
    while (my $line = <$handle>) {
        next unless $line =~ /^(\S+)\s*=\s*(\S+.*)/;
        my $key = $1;
        my $value = $2;
        $value =~ s/(^"|"$)//g;
        $info{$key} = $value;
    }
    close $handle;

    return %info;
}

1;
