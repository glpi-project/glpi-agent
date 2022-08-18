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

    # Try first to get registered containers so we also catch powered off containers
    my @nspawn = getAllLines(
        command => "systemctl --system --all -q --plain list-units systemd-nspawn@*",
        logger  => $params{logger}
    );

    my %machines;

    if (@nspawn) {
        foreach my $line (@nspawn) {
            my ($name, $state) = $line =~ /^systemd-nspawn\@(\S+)\.service\s+\w+\s+\w+\s+(\w+)/
                or next;

            my $status = STATUS_OFF;
            $status = STATUS_RUNNING if $state && $state eq "running";
            $machines{$name} = {
                NAME        => $name,
                VMTYPE      => "systemd-nspawn",
                VCPU        => 0,
                STATUS      => $status,
            };
        }
    }

    my @machines;

    # Parse machinectl to always report running containers, even if they are not registered
    foreach my $line (getAllLines(
        command => "machinectl --no-pager --no-legend",
        logger  => $params{logger}
    )) {
        my ($name, $class, $service) = $line =~ /^(\S+)\s+(\w+)\s+(\S+)/
            or next;

        # Don't inventory libvirt-qemu as still supported by Libvirt module
        next if $service && $service eq "libvirt-qemu";

        my $container;
        if ($machines{$name}) {
            $container = delete $machines{$name};
            $container->{SUBSYSTEM} = $class;
        } else {
            $container = {
                NAME        => $name,
                VMTYPE      => $service,
                SUBSYSTEM   => $class,
                VCPU        => 0,
                STATUS      => STATUS_RUNNING,
            };
        }

        push @machines, $container
    }

    # Add powered off machines to list
    push @machines, values(%machines);

    foreach my $container (@machines) {
        my $name = $container->{NAME};
        my $uuid;
        if ($container->{STATUS} eq STATUS_RUNNING) {
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
    }

    return @machines;
}

1;
