package FusionInventory::Agent::Task::Inventory::Vmsystem;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use UNIVERSAL::require;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::UUID;
use FusionInventory::Agent::Tools::Virtualization;

# We keep this module out of category as it is also mandatory for partial inventory

# Be sure to run after any module which can set BIOS or HARDWARE (only setting UUID)
our $runAfterIfEnabled = [ qw(
    FusionInventory::Agent::Task::Inventory::AIX::Bios
    FusionInventory::Agent::Task::Inventory::BSD::Alpha
    FusionInventory::Agent::Task::Inventory::BSD::i386
    FusionInventory::Agent::Task::Inventory::BSD::MIPS
    FusionInventory::Agent::Task::Inventory::BSD::SPARC
    FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Bios
    FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Hardware
    FusionInventory::Agent::Task::Inventory::HPUX::Bios
    FusionInventory::Agent::Task::Inventory::HPUX::Hardware
    FusionInventory::Agent::Task::Inventory::Linux::Bios
    FusionInventory::Agent::Task::Inventory::Linux::PowerPC::Bios
    FusionInventory::Agent::Task::Inventory::Linux::Hardware
    FusionInventory::Agent::Task::Inventory::Linux::ARM::Board
    FusionInventory::Agent::Task::Inventory::MacOS::Bios
    FusionInventory::Agent::Task::Inventory::MacOS::Hardware
    FusionInventory::Agent::Task::Inventory::Solaris::Bios
    FusionInventory::Agent::Task::Inventory::Solaris::Hardware
    FusionInventory::Agent::Task::Inventory::Win32::Bios
    FusionInventory::Agent::Task::Inventory::Win32::Hardware
)];

my @vmware_patterns = (
    'Hypervisor detected: VMware',
    'VMware vmxnet3? virtual NIC driver',
    'Vendor: VMware\s+Model: Virtual disk',
    'Vendor: VMware,\s+Model: VMware Virtual ',
    ': VMware Virtual IDE CDROM Drive'
);
my $vmware_pattern = _assemblePatterns(@vmware_patterns);

my @qemu_patterns = (
    ' QEMUAPIC ',
    'QEMU Virtual CPU',
    ': QEMU HARDDISK,',
    ': QEMU CD-ROM,',
    ': QEMU Standard PC',
    'Hypervisor detected: KVM',
    'Booting paravirtualized kernel on KVM'
);
my $qemu_pattern = _assemblePatterns(@qemu_patterns);

my @virtual_machine_patterns = (
    ': Virtual HD,',
    ': Virtual CD,'
);
my $virtual_machine_pattern = _assemblePatterns(@virtual_machine_patterns);

my @virtualbox_patterns = (
    ' VBOXBIOS ',
    ': VBOX HARDDISK,',
    ': VBOX CD-ROM,',
);
my $virtualbox_pattern = _assemblePatterns(@virtualbox_patterns);

my @xen_patterns = (
    'Hypervisor signature: xen',
    'Xen virtual console successfully installed',
    'Xen reported:',
    'Xen: \d+ - \d+',
    'xen-vbd: registered block device',
    'ACPI: [A-Z]{4} \(v\d+\s+Xen ',
);
my $xen_pattern = _assemblePatterns(@xen_patterns);

my %module_patterns = (
    '^vmxnet\s' => 'VMware',
    '^xen_\w+front\s' => 'Xen',
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

    } elsif (($type eq 'lxc' || ($type ne 'Physical' && !$inventory->getHardware('UUID'))) && -e '/etc/machine-id') {
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

    if (-f '/.dockerinit' || -f '/.dockerenv') {
        return 'Docker';
    }

    # Solaris zones
    if (canRun('/usr/sbin/zoneadm')) {
        if (FusionInventory::Agent::Tools::Solaris->require()) {
            my $zone = FusionInventory::Agent::Tools::Solaris::getZone();
            return 'SolarisZone' if $zone ne 'global';
        }
    }

    # Xen PV host
    if (
        -d '/proc/xen' ||
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

    if (canRun('/sbin/sysctl')) {
        my $handle = getFileHandle(
            command => '/sbin/sysctl -n security.jail.jailed',
            logger => $logger
        );
        my $line = <$handle>;
        close $handle;
        return 'BSDJail' if $line && $line == 1;
    }

    # loaded modules

    if (-f '/proc/modules') {
        my $handle = getFileHandle(
            file => '/proc/modules',
            logger => $logger
        );
        while (my $line = <$handle>) {
            foreach my $pattern (keys %module_patterns) {
                next unless $line =~ /$pattern/;
                $result = $module_patterns{$pattern};
                last;
            }
        }
        close $handle;
    }
    return $result if $result;

    # dmesg
    # dmesg can be empty or near empty on some systems (notably on Debian 8)

    my $handle;
    if (-r '/var/log/dmesg' && -s '/var/log/dmesg' > 40) {
        $handle = getFileHandle(file => '/var/log/dmesg', logger => $logger);
    } elsif (-x '/bin/dmesg') {
        $handle = getFileHandle(command => '/bin/dmesg', logger => $logger);
    } elsif (-x '/sbin/dmesg') {
        # On OpenBSD, dmesg is in sbin
        # http://forge.fusioninventory.org/issues/402
        $handle = getFileHandle(command => '/sbin/dmesg', logger => $logger);
    }

    if ($handle) {
        $result = _matchPatterns($handle);
        close $handle;
        return $result if $result;
    }

    # scsi

    if (-f '/proc/scsi/scsi') {
        my $handle = getFileHandle(
            file => '/proc/scsi/scsi',
            logger => $logger
        );
        if ($handle) {
            $result = _matchPatterns($handle);
            close $handle;
            return $result if $result;
        }
    }

    # systemd based container like lxc

    my $init_env = slurp('/proc/1/environ');
    if ($init_env) {
        $init_env =~ s/\0/\n/g;
        my $container_type = getFirstMatch(
            string  => $init_env,
            pattern => qr/^container=(\S+)/,
            logger  => $logger
        );
        return $container_type if $container_type;
    }
    # OpenVZ
    if (-f '/proc/self/status') {
        my @selfstatus = getAllLines(
            file => '/proc/self/status',
            logger => $logger
        );
        foreach my $line (@selfstatus) {
            my ($key, $value) = split(/:/, $line);
            $result = "Virtuozzo" if $key eq 'envID' && $value > 0;
        }
    }

    # WSL
    if (-e '/proc/sys/fs/binfmt_misc/WSLInterop') {
        $result = "WSL";
    } elsif (getFirstMatch(command => 'lscpu', pattern => qr/^Hypervisor vendor:\s+(Windows Subsystem for Linux|Microsoft)/)) {
        $result = "WSL";
    } elsif (getFirstMatch(file => '/proc/mounts', pattern => qr/^rootfs\s+\/\s+(wslfs)/)) {
        $result = "WSL";
    }

    return $result if $result;

    return 'Physical';
}

sub _assemblePatterns {
    my (@patterns) = @_;

    my $pattern = '(?:' . join('|', @patterns) . ')';
    return qr/$pattern/;
}

sub _matchPatterns {
    my ($handle) = @_;

    while (my $line = <$handle>) {
        return 'VMware'          if $line =~ $vmware_pattern;
        return 'QEMU'            if $line =~ $qemu_pattern;
        return 'Virtual Machine' if $line =~ $virtual_machine_pattern;
        return 'VirtualBox'      if $line =~ $virtualbox_pattern;
        return 'Xen'             if $line =~ $xen_pattern;
    }
}

1;
