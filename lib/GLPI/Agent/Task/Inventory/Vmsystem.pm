package GLPI::Agent::Task::Inventory::Vmsystem;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::UUID;
use GLPI::Agent::Tools::Virtualization;

# We keep this module out of category as it is also mandatory for partial inventory

# Be sure to run after any module which can set BIOS or HARDWARE (only setting UUID)
our $runAfterIfEnabled = [ qw(
    GLPI::Agent::Task::Inventory::AIX::Bios
    GLPI::Agent::Task::Inventory::BSD::Alpha
    GLPI::Agent::Task::Inventory::BSD::i386
    GLPI::Agent::Task::Inventory::BSD::MIPS
    GLPI::Agent::Task::Inventory::BSD::SPARC
    GLPI::Agent::Task::Inventory::Generic::Dmidecode::Bios
    GLPI::Agent::Task::Inventory::Generic::Dmidecode::Hardware
    GLPI::Agent::Task::Inventory::HPUX::Bios
    GLPI::Agent::Task::Inventory::HPUX::Hardware
    GLPI::Agent::Task::Inventory::Linux::Bios
    GLPI::Agent::Task::Inventory::Linux::PowerPC::Bios
    GLPI::Agent::Task::Inventory::Linux::Hardware
    GLPI::Agent::Task::Inventory::Linux::ARM::Board
    GLPI::Agent::Task::Inventory::MacOS::Bios
    GLPI::Agent::Task::Inventory::MacOS::Hardware
    GLPI::Agent::Task::Inventory::Solaris::Bios
    GLPI::Agent::Task::Inventory::Solaris::Hardware
    GLPI::Agent::Task::Inventory::Win32::Bios
    GLPI::Agent::Task::Inventory::Win32::Hardware
)];

my @vmware_patterns = (
    'Hypervisor detected: VMware',
    'VMware vmxnet3? virtual NIC driver',
    'Vendor: VMware\s+Model: Virtual disk',
    'Vendor: VMware,\s+Model: VMware Virtual ',
    ': VMware Virtual IDE CDROM Drive'
);

my @qemu_patterns = (
    ' QEMUAPIC ',
    'QEMU Virtual CPU',
    ': QEMU HARDDISK,',
    ': QEMU CD-ROM,',
    ': QEMU Standard PC',
    'Hypervisor detected: KVM',
    'Booting paravirtualized kernel on KVM'
);

my @virtual_machine_patterns = (
    ': Virtual HD,',
    ': Virtual CD,'
);

my @virtualbox_patterns = (
    ' VBOXBIOS ',
    ': VBOX HARDDISK,',
    ': VBOX CD-ROM,',
);

my @xen_patterns = (
    'Hypervisor signature: xen',
    'Xen virtual console successfully installed',
    'Xen reported:',
    'Xen: \d+ - \d+',
    'xen-vbd: registered block device',
    'ACPI: [A-Z]{4} \(v\d+\s+Xen ',
);

my %match_patterns = (
    VMware              => _assemblePatterns(@vmware_patterns),
    QEMU                => _assemblePatterns(@qemu_patterns),
    'Virtual Machine'   => _assemblePatterns(@virtual_machine_patterns),
    VirtualBox          => _assemblePatterns(@virtualbox_patterns),
    Xen                 => _assemblePatterns(@xen_patterns),
);
my @match_patterns_orderer = ('VMware', 'QEMU', 'Virtual Machine', 'VirtualBox', 'Xen');

my %module_patterns = (
    VMware  => qr/^vmxnet\s/,
    Xen     => qr/^xen_\w+front\s/,
);

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $type = _getType($inventory, $logger);

    # for consistency with HVM domU
    if ($type eq 'Xen' && !$inventory->getBios('SMANUFACTURER')) {
        $inventory->setBios({
            SMANUFACTURER => 'Xen',
            SMODEL => 'PVM domU'
        });
    }

    # compute a compound identifier, as Virtuozzo uses the same identifier
    # for the host and for the guests
    if ($type eq 'Virtuozzo') {
        my $hostID  = $inventory->getHardware('UUID') || '';
        my $guestID = getFirstMatch(
            file => '/proc/self/status',
            pattern => qr/^envID:\s*(\d+)/
        ) || '';
        $inventory->setHardware({ UUID => $hostID . '-' . $guestID })
            if length($hostID) && length($guestID);

    } elsif ($type eq 'Docker') {
        # In docker, dmidecode can be run and so UUID & SSN must be overided
        my $containerid = getFirstMatch(
            file    => '/proc/1/cgroup',
            pattern => qr|/docker/([0-9a-f]{12})|,
            logger  => $params{logger}
        );

        $inventory->setHardware({ UUID => $containerid || '' });
        $inventory->setBios({ SSN  => '' });

    } elsif ($type eq "WSL") {
        my ($user, $sid) = getFirstMatch(
            command => "whoami.exe /nh /user /fo csv",
            pattern => qr|^"(.*)","(.*)"|,
            logger  => $params{logger}
        );
        if (defined($user) && defined($sid)) {
            $user =~ s/^.*\\//;
            my $distro = $ENV{"WSL_DISTRO_NAME"} // '';
            # Same UUID computing than in WSL.pm
            my $uuid = uc(create_uuid_from_name($sid."/".$distro));
            $inventory->setHardware({ UUID => $uuid }) if $uuid;
            my $hostname = "$distro on $user account";
            $inventory->setHardware({ NAME => $hostname });
        }

    } elsif ($type eq "systemd-nspawn") {
        my $uuid;
        if (canRead("/run/host/container-uuid")) {
            $uuid = getAllLines(
                file    => "/run/host/container-uuid",
                logger  => $logger
            );
        } elsif (canRead("/proc/1/environ")) {
            my $init_env = getAllLines(
                file    => '/proc/1/environ',
                logger  => $logger
            );
            if ($init_env) {
                $init_env =~ s/\0/\n/g;
                $uuid = getFirstMatch(
                    string  => $init_env,
                    pattern => qr/^container_uuid=(\S+)/,
                    logger  => $logger
                );
            }
        }
        $inventory->setHardware({ UUID => $uuid }) if $uuid;
        if (-d "/run/host/incoming") {
            my $name = getFirstMatch(
                file    => "/proc/1/mountinfo",
                pattern => qr{/systemd/nspawn/propagate/(\S+) /run/host/incoming},
                logger  => $logger
            );
            $inventory->setHardware({ NAME => $name }) if $name;
        }
    } elsif (($type eq 'lxc' || ($type ne 'Physical' && !$inventory->getHardware('UUID'))) && has_file('/etc/machine-id')) {
        # Set UUID from /etc/machine-id & /etc/hostname for container like lxc
        my $machineid = getFirstLine(
            file   => '/etc/machine-id',
            logger => $params{logger}
        );
        my $hostname = getFirstLine(
            file   => '/etc/hostname',
            logger => $params{logger}
        );

        if ($machineid && $hostname) {
            $inventory->setHardware({ UUID => getVirtualUUID($machineid, $hostname) });
        }
    }

    $inventory->setHardware({
        VMSYSTEM => $type,
    });
}

sub _getType {
    my ($inventory, $logger) = @_;

    # First check if we are in a container before checking virtualization as we
    # still can detect the host is virtualized

    if (canRun('/sbin/sysctl')) {
        my $line = getFirstLine(
            command => '/sbin/sysctl -n security.jail.jailed',
            logger => $logger
        );
        return 'BSDJail' if $line && $line == 1;
    }

    # systemd based container like lxc or systemd-nspawn should be tested before
    if (canRead('/proc/1/environ')) {
        my $init_env = getAllLines(
            file => '/proc/1/environ',
            no_error_log => 1,
            logger => $logger
        );
        if ($init_env) {
            $init_env =~ s/\0/\n/g;
            my $container_type = getFirstMatch(
                string  => $init_env,
                pattern => qr/^container=(\S+)/,
                logger  => $logger
            );
            return $container_type if $container_type;
        }
    }

    # OpenVZ
    if (canRead('/proc/self/status')) {
        my @selfstatus = getAllLines(
            file => '/proc/self/status',
            logger => $logger
        );
        foreach my $line (@selfstatus) {
            my ($key, $value) = split(/:/, $line);
            return "Virtuozzo" if $key eq 'envID' && $value > 0;
        }
    }

    # WSL
    if (has_file('/proc/sys/fs/binfmt_misc/WSLInterop')) {
        return "WSL";
    } elsif (canRun('lscpu') && getFirstMatch(command => 'lscpu', pattern => qr/^Hypervisor vendor:\s+(Windows Subsystem for Linux|Microsoft)/)) {
        return "WSL";
    } elsif (has_file('/proc/mounts') && getFirstMatch(file => '/proc/mounts', pattern => qr/^rootfs\s+\/\s+(wslfs)/)) {
        return "WSL";
    }

    my $SMANUFACTURER = $inventory->getBios('SMANUFACTURER');
    my $SMODEL        = $inventory->getBios('SMODEL');
    if ($SMANUFACTURER) {
        return 'QEMU'    if $SMANUFACTURER =~ /QEMU/;
        return 'Hyper-V' if $SMANUFACTURER =~ /Microsoft/ && $SMODEL && $SMODEL =~ /Virtual/;
        return 'VMware'  if $SMANUFACTURER =~ /VMware/;
        return 'Xen'     if $SMANUFACTURER =~ /^Xen/;
    }
    my $BMANUFACTURER = $inventory->getBios('BMANUFACTURER');
    if ($BMANUFACTURER) {
        return 'QEMU'       if $BMANUFACTURER =~ /(QEMU|Bochs)/;
        return 'VirtualBox' if $BMANUFACTURER =~ /(VirtualBox|innotek)/;
        return 'Xen'        if $BMANUFACTURER =~ /^Xen/;
    }
    if ($SMODEL) {
        return 'VMware'          if $SMODEL =~ /VMware/;
        return 'Virtual Machine' if $SMODEL =~ /Virtual Machine/;
        return 'QEMU'            if $SMODEL =~ /KVM/;
    }
    my $BVERSION = $inventory->getBios('BVERSION');
    if ($BVERSION) {
        return 'VirtualBox'  if $BVERSION =~ /VirtualBox/;
    }
    my $MMODEL = $inventory->getBios('MMODEL');
    if ($MMODEL) {
        return 'VirtualBox'  if $MMODEL =~ /VirtualBox/;
    }
    my $VERSION = $inventory->getBios('VERSION');
    if ($VERSION) {
        return 'VirtualBox'  if $VERSION =~ /VirtualBox/;
    }
    # Can only be set by win32
    my $BIOSSERIAL = $inventory->getBios('BIOSSERIAL');
    if ($BIOSSERIAL) {
        return 'VMware'      if $BIOSSERIAL =~ /VMware/i;
    }

    # Docker

    if (has_file('/.dockerinit') || has_file('/.dockerenv')) {
        return 'Docker';
    }

    # Solaris zones
    if (OSNAME eq 'solaris' && canRun('/usr/sbin/zoneadm')) {
        if (GLPI::Agent::Tools::Solaris->require()) {
            my $zone = GLPI::Agent::Tools::Solaris::getZone();
            return 'SolarisZone' if $zone ne 'global';
        }
    }

    # Xen PV host
    if (
        has_folder('/proc/xen') ||
        getFirstMatch(
            file    => '/sys/devices/system/clocksource/clocksource0/available_clocksource',
            pattern => qr/xen/
        )
    ) {
        if (getFirstMatch(
            file    => '/proc/xen/capabilities',
            pattern => qr/control_d/
        )) {
            # dom0 host
            return 'Physical';
        } else {
            # domU PV host
            return 'Xen';
        }
    }

    my $result;

    # loaded modules

    if (canRead('/proc/modules')) {
        my @lines = getAllLines(
            file => '/proc/modules',
            logger => $logger
        );
        foreach my $type (keys(%module_patterns)) {
            return $type if any { $_ =~ $module_patterns{$type} } @lines;
        }
    }

    # dmesg
    # dmesg can be empty or near empty on some systems (notably on Debian 8)

    my @lines;
    if (canRead('/var/log/dmesg') && FileStat('/var/log/dmesg')->size > 40) {
        @lines = getAllLines(file => '/var/log/dmesg', logger => $logger);
    } elsif (canRun('/bin/dmesg')) {
        @lines = getAllLines(command => '/bin/dmesg', logger => $logger);
    } elsif (canRun('/sbin/dmesg')) {
        # On OpenBSD, dmesg is in sbin
        # http://forge.fusioninventory.org/issues/402
        @lines = getAllLines(command => '/sbin/dmesg', logger => $logger);
    }

    if (@lines) {
        $result = _matchPatterns(\@lines);
        return $result if $result;
    }

    # scsi

    if (canRead('/proc/scsi/scsi')) {
        my @lines = getAllLines(
            file => '/proc/scsi/scsi',
            logger => $logger
        );
        if (@lines) {
            $result = _matchPatterns(\@lines);
            return $result if $result;
        }
    }

    return 'Physical';
}

sub _assemblePatterns {
    my (@patterns) = @_;

    my $pattern = '(?:' . join('|', @patterns) . ')';
    return qr/$pattern/;
}

sub _matchPatterns {
    my ($lines) = @_;

    foreach my $line (@{$lines}) {
        my $type = first { $line =~ $match_patterns{$_} } @match_patterns_orderer;
        return $type if $type;
    }
}

1;
