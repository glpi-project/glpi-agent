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
        canRun('vmrun') ||
        canRun('C:\\\\Program Files (x86)\\\\VMware\\\\VMware Workstation\\\\vmrun.exe');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $command;
    
    if (canRun('vmrun')) {
        $command = 'vmrun list';
    }
    elsif (canRun('/Library/Application Support/VMware Fusion/vmrun')) {
        $command = "'/Library/Application Support/VMware Fusion/vmrun' list";
    }
    elsif (canRun('C:\\\\Program Files (x86)\\\\VMware\\\\VMware Workstation\\\\vmrun.exe')) {
        # specify Workstation target with -T ws
        $command = '"C:\\\\Program Files (x86)\\\\VMware\\\\VMware Workstation\\\\vmrun.exe" list';
    }
    else {
        return;
    }


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

    my @lines = getAllLines(%params)
        or return;

    # skip first line
    shift @lines;
    
    my $subsystem = ($^O eq 'MSWin32') ? "VmWare Workstation" : "VmWare Fusion";
    my @machines;
    foreach my $line (@lines) {
        next unless has_file($line);

        my %info = _getMachineInfo(file => $line, logger => $params{logger});

        my $machine = {
            NAME      => $info{'displayname'},
            VCPU      => $info{'numvcpus'},
            UUID      => $info{'uuid.bios'},
            MEMORY    => $info{'memsize'},
            STATUS    => STATUS_RUNNING,
            SUBSYSTEM => $subsystem,
            VMTYPE    => "VmWare",
        };

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
        next unless $line =~ /^(\S+)\s*=\s*(\S+.*)/;
        my $key = $1;
        my $value = $2;
        $value =~ s/(^"|"$)//g;
        $info{$key} = $value;
    }

    return %info;
}

1;
