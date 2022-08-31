package GLPI::Agent::Task::Inventory::Virtualization::XenCitrixServer;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Virtualization;

our $runMeIfTheseChecksFailed = ["GLPI::Agent::Task::Inventory::Virtualization::Libvirt"];

sub isEnabled {
    return canRun('xe');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @machines = _getVirtualMachines(
        command => 'xe vm-list',
        logger  => $logger
    );

    foreach my $machine (@machines) {

        my $machineextend = _getVirtualMachine(
            command => "xe vm-param-list uuid=".$machine->{UUID},
            logger  => $logger,
        );

        # Skip the machine if Dom0
        next unless $machineextend;

        foreach my $key (keys(%{$machineextend})) {
            $machine->{$key} = $machineextend->{$key};
        }

        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub _getVirtualMachines {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @machines;
    foreach my $line (@lines) {

        my ($uuid) = $line =~ /uuid *\( *RO\) *: *([-0-9a-f]+) *$/;
        next unless $uuid;

        my $machine = {
            UUID      => $uuid,
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen',
        };

        push @machines, $machine;

    }

    return @machines;
}

sub  _getVirtualMachine {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $machine;

    foreach my $line (@lines) {

        # Lines format: extended-label (...): value(s)
        my ($extendedlabel, $value) =
            $line =~ /^\s*(\S+)\s*\(...\)\s*:\s*(.*)$/ ;

        next unless $extendedlabel;

        # dom-id 0 is not a VM
        if ($extendedlabel =~ /dom-id/ && !int($value)) {
            undef $machine;
            last;
        }
        if ($extendedlabel =~ /name-label/) {
            $machine->{NAME} = $value;
            next;
        }
        if ($extendedlabel =~ /memory-actual/) {
            $machine->{MEMORY} = ($value / 1048576);
            next;
        }
        if ($extendedlabel =~ /power-state/) {
            $machine->{STATUS} =
                $value eq 'running' ? 'running'  :
                $value eq 'halted'  ? 'shutdown' :
                'off';
            next;
        }
        if ($extendedlabel =~ /VCPUs-number/) {
            $machine->{VCPU} = $value;
            next;
        }
        if ($extendedlabel =~ /name-description/) {
            next if $value eq '';
            $machine->{COMMENT} = $value;
            next;
        }
    }

    return $machine;
}

1;
