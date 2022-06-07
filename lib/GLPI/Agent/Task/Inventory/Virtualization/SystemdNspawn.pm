package GLPI::Agent::Task::Inventory::Virtualization::SystemdNspawn;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Linux;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Virtualization;

sub isEnabled {
    return canRun("machinectl") && canRun("systemctl");
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my @machines = _getVirtualMachines( logger => $params{logger} );

    foreach my $machine (@machines) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub  _getVirtualMachines {
    my (%params) = @_;

    my @nspawn = getAllLines(
        command => "systemctl --system --all -q --plain list-units systemd-nspawn@*",
        logger  => $params{logger}
    ) or return;

    my @machines;

    foreach my $line (@nspawn) {

        my ($name, $state) = $line =~ /^systemd-nspawn\@(\S+)\.service\s+\w+\s+\w+\s+(\w+)/
            or next;

        my $status = STATUS_OFF;
        $status = STATUS_RUNNING if $state && $state eq "running";

        my $container = {
            NAME        => $name,
            VMTYPE      => "systemd-nspawn",
            VCPU        => 0,
            STATUS      => $status,
        };

        my $uuid;
        if ($status eq STATUS_RUNNING) {
            $uuid = getFirstMatch(
                command => "machinectl show -p Id $name",
                pattern => qr/^Id=(\w+)$/,
                logger  => $params{logger}
            );
        } else {
            my $mount = getFirstLine(
                command => "systemctl --system show systemd-nspawn\@$name.service -P RequiresMountsFor",
                logger  => $params{logger}
            );
            if ($mount && -d $mount && -e "$mount/etc/machine-id") {
                $uuid = getFirstLine(
                    file => "$mount/etc/machine-id",
                    logger  => $params{logger}
                );
            }
        }
        if ($uuid) {
            $uuid = "$1-$2-$3-$4-$5"
                if $uuid =~ /^(\w{8})(\w{4})(\w{4})(\w{4})(\w{12})$/;
            $container->{UUID} = $uuid;
        }

        foreach my $line (getAllLines(
            command => "systemctl --system cat systemd-nspawn\@$name.service",
            logger  => $params{logger}
        )) {
            if ($line =~ /^CPUQuota=(\d+)%/) {
                $container->{VCPU} = int($1/100);
            } elsif ($line =~ /^MemoryMax=(\d+)$/) {
                $container->{MEMORY} = getCanonicalSize($1." bytes", 1024);
            }
        }

        # Set VCPU to max host cpus count if not set
        if (!$container->{VCPU}) {
            $container->{VCPU} = getCPUsFromProc(logger => $params{logger});
        }

        push @machines, $container;
    }

    return @machines;
}

1;
