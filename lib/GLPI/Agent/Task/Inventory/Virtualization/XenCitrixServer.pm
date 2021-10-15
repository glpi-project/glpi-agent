package FusionInventory::Agent::Task::Inventory::Virtualization::XenCitrixServer;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Virtualization;

our $runMeIfTheseChecksFailed = ["FusionInventory::Agent::Task::Inventory::Virtualization::Libvirt"];

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

    my $handle = getFileHandle(@_);

    return unless $handle;

    my @machines;
    while (my $line = <$handle>) {

        my ($uuid) = $line =~ /uuid *\( *RO\) *: *([-0-9a-f]+) *$/;
        next unless $uuid;

        my $machine = {
            UUID      => $uuid,
            SUBSYSTEM => 'xe',
            VMTYPE    => 'xen',
        };

        push @machines, $machine;

    }
    close $handle;

    return @machines;
}

sub  _getVirtualMachine {

    my $handle = getFileHandle(@_);

    return unless $handle;

    my $machine;

    while (my $line = <$handle>) {

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
    close $handle;

    return $machine;
}

1;
