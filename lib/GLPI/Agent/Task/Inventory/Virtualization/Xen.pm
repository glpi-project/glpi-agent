package GLPI::Agent::Task::Inventory::Virtualization::Xen;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Virtualization;

our $runMeIfTheseChecksFailed = [
    "GLPI::Agent::Task::Inventory::Virtualization::Libvirt",
    "GLPI::Agent::Task::Inventory::Virtualization::XenCitrixServer"
];

sub isEnabled {
    return canRun('xm') ||
           canRun('xl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my ($toolstack, $listParam) = ('xm', '-l');
    my @lines = getAllLines(
        command => 'xm list',
        logger  => $logger
    );
    unless (@lines) {
        ($toolstack, $listParam) = ('xl', '-v');
        @lines = getAllLines(
            command => 'xl list',
            logger  => $logger
        );
    }
    return unless @lines;

    $logger->info("Xen $toolstack toolstack detected");

    foreach my $machine (_getVirtualMachines(lines => \@lines, logger => $logger)) {
        $machine->{SUBSYSTEM} = $toolstack;
        my $uuid = _getUUID(
            command => "$toolstack list $listParam $machine->{NAME}",
            logger  => $logger
        );
        $machine->{UUID} = $uuid;
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );

        $logger->debug("$machine->{NAME}: [$uuid]");
    }
}

sub _getUUID {
    my (%params) = @_;

    return getFirstMatch(
        pattern => qr/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/xi,
        %params
    );
}

sub  _getVirtualMachines {
    my (%params) = @_;

    return unless $params{lines} && @{$params{lines}};

    # xm status
    my %status_list = (
        'r' => STATUS_RUNNING,
        'b' => STATUS_BLOCKED,
        'p' => STATUS_PAUSED,
        's' => STATUS_SHUTDOWN,
        'c' => STATUS_CRASHED,
        'd' => STATUS_DYING
    );

    # drop headers
    shift @{$params{lines}};

    my @machines;
    foreach my $line (@{$params{lines}}) {
        next if $line =~ /^\s*$/;
        my ($name, $vmid, $memory, $vcpu, $status);
        my @fields = split(' ', $line);
        if (@fields == 4) {
            ($name, $memory, $vcpu) = @fields;
            $status = STATUS_OFF;
        } else {
            if ($line =~ /^(.*\S) \s+ (\d+) \s+ (\d+) \s+ (\d+) \s+ ([a-z-]{5,6}) \s/x) {
                ($name, $vmid, $memory, $vcpu, $status) = ($1, $2, $3, $4, $5);
            } else {
                if ($params{logger}) {
                    # message in log to easily detect matching errors
                    my $message = '_getVirtualMachines(): unrecognized output';
                    $message .= " for command '" . $params{command} . "'";
                    $message .= ': ' . $line;
                    $params{logger}->error($message);
                }
                next;
            }
            $status =~ s/-//g;
            $status = $status ? $status_list{$status} : STATUS_OFF;
            next if $vmid == 0;
        }
        next if $name eq 'Domain-0';

        my $machine = {
            MEMORY    => $memory,
            NAME      => $name,
            STATUS    => $status,
            SUBSYSTEM => 'xm',
            VMTYPE    => 'xen',
            VCPU      => $vcpu,
        };

        push @machines, $machine;
    }

    return @machines;
}

1;
