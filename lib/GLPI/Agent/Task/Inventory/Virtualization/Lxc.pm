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
    return canRun('lxc-ls') || canRun('pct');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Check if we require to list containers using proxmox pct command
    my @machines = _getVirtualMachines(
        runpct => canRun('pct'),
        logger => $params{logger}
    );

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

    my $name   = $params{name};
    my $ctid   = $params{ctid} // $name;
    my $config = "$params{lxcpath}/$ctid/config";
    my $container = {
        NAME    => $name,
        VMTYPE  => 'lxc',
        VCPU    => 0,
        STATUS  => _getVirtualMachineState(
            command => $params{test_cmdstate} || "lxc-info -n '$ctid' -s",
            logger => $params{logger}
        )
    };

    # Proxmox environment sets name as number and it should have been passed as ctid
    my $proxmox = $ctid =~ /^\d+$/ ? 1 : 0;

    my $command = "lxc-info -n '$ctid' -c lxc.cgroup.memory.limit_in_bytes -c lxc.cgroup2.memory.max -c lxc.cgroup.cpuset.cpus -c lxc.cgroup2.cpuset.cpus";
    if ($params{version} < 2.1) {
        # Before 2.1, we need to find MAC as lxc.network.hwaddr in config
        $command .= "; grep lxc.network.hwaddr $config";
        # Look for lxc.utsname from config file in Proxmox environment
        $command .= "; grep utsname $config" if $proxmox;
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

        if ($key eq 'lxc.cgroup.memory.limit_in_bytes' || $key eq 'lxc.cgroup2.memory.max') {
            $val .= $val =~ /[KMGTP]$/i ? "b" : $val =~ /^\d+$/ ? "bytes" : "";
            $container->{MEMORY} = getCanonicalSize($val, 1024);
        }

        # Update container name in Proxmox environment
        if ($proxmox && ($key eq 'lxc.uts.name' || $key eq 'lxc.utsname')) {
            $container->{NAME} = $val;
        }

        if ($key eq 'lxc.cgroup.cpuset.cpus' || $key eq 'lxc.cgroup2.cpuset.cpus') {
            ###eg: lxc.cgroup.cpuset.cpus = 0,3-5,7,2,1
            $container->{VCPU} = 0;
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
        command => $params{runpct} ? 'pct list' : 'lxc-ls -1',
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
    my $pct_name_offset = 0;

    my @machines;

    foreach my $name (@lines) {
        my $vmid;
        # Support pct when running with proxmox
        if ($params{runpct}) {
            if ($name =~ /^(VMID\s.*\s)Name.*$/) {
                $pct_name_offset = length($1);
                next;
            } elsif ($pct_name_offset) {
                $vmid = $1 if $name =~ m/^(\d+)/;
                $name = substr($name, $pct_name_offset);
            } else {
                next;
            }
        }

        # lxc-ls -1 shows one entry by line
        $name =~ s/\s+$//;         # trim trailing whitespace
        next unless length($name); # skip if empty as name can contain space

        # Handle proxmox case using vmid as container name in commands
        my $ctid = $params{runpct} && $vmid ? $vmid : $name;

        my $container = _getVirtualMachine(
            name    => $name,
            ctid    => $ctid,
            version => $version,
            lxcpath => $lxcpath,
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
                command => "lxc-attach -n '$ctid' -- /bin/cat /etc/machine-id",
                logger => $params{logger}
            );
            $hostname = getFirstLine(
                command => "lxc-attach -n '$ctid' -- /bin/cat /etc/hostname",
                logger => $params{logger}
            );
        } else {
            # Try to directly access container filesystem for not powered container
            # Works for standard fs or overlay rootfs
            my $rootfs = getFirstMatch(
                command => "/usr/bin/lxc-info -n '$ctid' -c $rootfs_conf",
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
