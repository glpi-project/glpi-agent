package GLPI::Agent::Task::Inventory::Virtualization::Lxc;

# Authors: Egor Shornikov <se@wbr.su>, Egor Morozov <akrus@flygroup.st>
# License: GPLv2+

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Linux;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Virtualization;

sub isEnabled {
    return canRun('lxc-ls');
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

sub  _getVirtualMachineState {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $state = STATUS_OFF;
    foreach my $line (@lines) {
        if ($line =~ m/^State:\s*(\S+)$/i) {
            $state = $1 eq 'RUNNING' ? STATUS_RUNNING :
                     $1 eq 'FROZEN'  ? STATUS_PAUSED  :
                     STATUS_OFF;
            last;
        }
    }

    return $state;
}

sub  _getVirtualMachine {
    my (%params) = @_;

    my $name = $params{name};
    my $container = {
        NAME    => $name,
        VMTYPE  => 'lxc',
        VCPU    => 0,
        STATUS  => _getVirtualMachineState(
            command => $params{test_cmdstate} || "lxc-info -n '$name' -s",
            logger => $params{logger}
        )
    };

    # Proxmox environment sets name as number
    my $proxmox = $name =~ /^\d+$/ ? 1 : 0;

    my $command = "lxc-info -n '$name' -c lxc.cgroup.memory.limit_in_bytes -c lxc.cgroup.cpuset.cpus";
    if ($params{version} < 2.1) {
        # Before 2.1, we need to find MAC as lxc.network.hwaddr in config
        $command .= "; grep lxc.network.hwaddr $params{config}";
        # Look for lxc.utsname from config file in Proxmox environment
        $command .= "; grep utsname $params{config}" if $proxmox;
    } else {
        $command .= " -c lxc.net.0.hwaddr";
        # Look for lxc.uts.name in Proxmox environment
        $command .= " -c lxc.uts.name" if $proxmox;
    }

    my @lines = getAllLines(
        command => $params{test_cmdinfo} || $command,
        logger  => $params{logger}
    );
    return unless @lines;

    foreach my $line (@lines) {
        next if $line =~ /^#.*/;
        next unless $line =~ m/^\s*(\S+)\s*=\s*(\S+)\s*$/;

        my $key = $1;
        my $val = $2;
        if ($key eq 'lxc.network.hwaddr' || $key eq 'lxc.net.0.hwaddr') {
            $container->{MAC} = lc($val)
                if $val =~ $mac_address_pattern;
        }

        if ($key eq 'lxc.cgroup.memory.limit_in_bytes') {
            $val .= "b" if $val =~ /[KMGTP]$/i;
            $container->{MEMORY} = getCanonicalSize($val, 1024);
        }

        # Update container name in Proxmox environment
        if ($proxmox && ($key eq 'lxc.uts.name' || $key eq 'lxc.utsname')) {
            $container->{NAME} = $val;
        }

        if ($key eq 'lxc.cgroup.cpuset.cpus') {
            ###eg: lxc.cgroup.cpuset.cpus = 0,3-5,7,2,1
            foreach my $cpu ( split( /,/, $val ) ){
                if ( $cpu =~ /(\d+)-(\d+)/ ){
                    $container->{VCPU} += $2 - $1 + 1;
                } else {
                    $container->{VCPU} += 1;
                }
            }
        }
    }

    return $container;
}

sub  _getVirtualMachines {
    my (%params) = @_;

    my @lines = getAllLines(
        command => 'lxc-ls -1',
        %params
    );
    return unless @lines;

    my $version = getFirstMatch(
        command => "lxc-ls --version",
        pattern => qr/^(\d+\.\d+)/,
        %params
    );

    my $lxcpath = getFirstLine(
        command => "lxc-config lxc.lxcpath",
        %params
    ) || "/var/lib/lxc";

    my $rootfs_conf = $version < 2.1 ? "lxc.rootfs" : "lxc.rootfs.path";
    my $max_cpus = 0;

    my @machines;

    foreach my $name (@lines) {
        # lxc-ls -1 shows one entry by line
        $name =~ s/\s+$//;         # trim trailing whitespace
        next unless length($name); # skip if empty as name can contain space

        my $container = _getVirtualMachine(
            name    => $name,
            version => $version,
            config  => "$lxcpath/$name/config",
            logger  => $params{logger}
        );

        # Set VCPU to max host cpus count if not set in conf
        if (!$container->{VCPU}) {
            $max_cpus = getCPUsFromProc(logger => $params{logger})
                unless $max_cpus;
            $container->{VCPU} = $max_cpus;
        }

        my ($machineid, $hostname);
        if ( $container->{STATUS} && $container->{STATUS} eq STATUS_RUNNING ) {
            $machineid = getFirstLine(
                command => "lxc-attach -n '$name' -- /bin/cat /etc/machine-id",
                logger => $params{logger}
            );
            $hostname = getFirstLine(
                command => "lxc-attach -n '$name' -- /bin/cat /etc/hostname",
                logger => $params{logger}
            );
        } else {
            # Try to directly access container filesystem for not powered container
            # Works for standard fs or overlay rootfs
            my $rootfs = getFirstMatch(
                command => "/usr/bin/lxc-info -n '$name' -c $rootfs_conf",
                pattern => qr/^lxc\.rootfs.*\s*=\s*(.*)$/,
                logger  => $params{logger}
            );
            $rootfs =~ s/.*:// if $rootfs =~ /:/;
            if (canRead("$rootfs/etc/machine-id") && canRead("$rootfs/etc/hostname")) {
                $machineid = getFirstLine(
                    file   => "$rootfs/etc/machine-id",
                    logger => $params{logger}
                );
                $hostname = getFirstLine(
                    file   => "$rootfs/etc/hostname",
                    logger => $params{logger}
                );
            }
        }

        my $uuid = getVirtualUUID($machineid, $hostname);
        $container->{UUID} = $uuid if $uuid;

        push @machines, $container;
    }

    return @machines;
}

1;
