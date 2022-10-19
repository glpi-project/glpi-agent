package GLPI::Agent::Task::Inventory::Virtualization::Wsl;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::UUID;
use GLPI::Agent::Tools::Virtualization;

our $runAfterIfEnabled = [ qw(
    GLPI::Agent::Task::Inventory::Win32::Hardware
    GLPI::Agent::Task::Inventory::Win32::CPU
)];

sub isEnabled {
    return OSNAME eq "MSWin32" && canRun('wsl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my @machines = _getUsersWslInstances(%params);

    foreach my $machine (@machines) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub  _getUsersWslInstances {
    my (%params) = @_;

    my @machines;

    # Always load Win32 API as late as possible
    GLPI::Agent::Tools::Win32->require();
    GLPI::Agent::Tools::Win32::Users->require();

    # Prepare vcpu, memory and a serial from still inventoried CPUS, HARDWARE & BIOS
    my $cpus = $params{inventory}->getSection('CPUS') // [{}];
    my $vcpu = 0;
    map { $vcpu += $_->{CORE} // 1 } @{$cpus};
    my $memory = $params{inventory}->getHardware('MEMORY');

    # Get system build revision to handle default max memory with WSL2
    my ($operatingSystem) = GLPI::Agent::Tools::Win32::getWMIObjects(
        class      => 'Win32_OperatingSystem',
        properties => [ qw/Version/ ]
    );
    my $kernel_version = $operatingSystem->{Version} // '';
    my ($build) = $kernel_version =~ /^\d+\.\d+\.(\d+)/;

    # Search users profiles for existing WSL instance
    foreach my $user (GLPI::Agent::Tools::Win32::Users::getSystemUserProfiles()) {
        my $sid = $user->{SID};

        my ($lxsskey, $userhive);
        unless ($user->{LOADED}) {
            my $ntuserdat = $user->{PATH}."/NTUSER.DAT";
            # This call involves we use cleanupPrivileges before leaving
            $userhive = GLPI::Agent::Tools::Win32::loadUserHive( sid => $sid, file => $ntuserdat );
        }
        $lxsskey = GLPI::Agent::Tools::Win32::getRegistryKey(
            path        => "HKEY_USERS/$sid/SOFTWARE/Microsoft/Windows/CurrentVersion/Lxss/",
            # Important for remote inventory optimization
            required    => [ qw/BasePath DistributionName/ ],
        )
            or next;

        # Support WSL2 memory/vcpu configuration
        my ($usermem, $uservcpu);
        if (has_file($user->{PATH}."/.wslconfig")) {
            ($usermem, $uservcpu) = _parseWslConfig(
                file    => $user->{PATH}."/.wslconfig",
                %params
            );
        }

        foreach my $sub (keys(%{$lxsskey})) {
            # We will use install GUID as WSL instance UUID
            next unless $sub =~ /^{(........-....-....-....-............)}\/$/;
            my $basepath = $lxsskey->{$sub}->{'/BasePath'}
                or next;
            my $distro = $lxsskey->{$sub}->{'/DistributionName'}
                or next;
            my $username = GLPI::Agent::Tools::Win32::Users::getProfileUsername($user);
            my $hostname = $username ? "$distro on $username account" : "$distro on $sid profile";

            # Create an UUID based on user SID and distro name
            my $uuid = uc(create_uuid_from_name($user->{SID}."/".$distro));

            my $version = has_folder($basepath."/rootfs/etc") ? "1" : "2";

            my $maxmemory = $memory;
            my $maxvcpu = $vcpu;
            if ($version eq "2") {
                $maxvcpu = $uservcpu if $uservcpu;
                if ($usermem) {
                    $maxmemory = $usermem;
                } elsif ($build && $build < 20175) {
                    # See https://docs.microsoft.com/en-us/windows/wsl/wsl-config#wsl-2-settings
                    # By default 80% of total memory on older builds
                    $maxmemory = int(0.8 * $memory);
                } else {
                    # By default the less of 50% of total memory or 8GB
                    $maxmemory = int(0.5 * $memory);
                    $maxmemory = 8192 if $maxmemory > 8192;
                }
            }

            push @machines, {
                NAME        => $hostname,
                VMTYPE      => "WSL$version",
                SUBSYSTEM   => "WSL",
                VCPU        => $uservcpu // $vcpu,
                MEMORY      => $maxmemory,
                UUID        => $uuid,
            };
        }

        # Free memory before leaving the block to avoid a Win32API error while
        # userhive is automatically unloaded
        undef $lxsskey if $userhive;
    }

    GLPI::Agent::Tools::Win32::cleanupPrivileges();

    return @machines;
}

sub _parseWslConfig {
    my (%params) = @_;

    my ($memory, $vcpu, $wsl2);

    foreach my $line (getAllLines(%params)) {
        # Find wsl2 section
        if ($line =~ /^\[(.*)\]/) {
            if ($1 eq "wsl2") {
                $wsl2 = 1;
            } else {
                $wsl2 = 0;
            }
            next;
        }
        next unless $wsl2;
        # Analyse wsl2 section lines
        if (my ($size) = $line =~ /^memory\s*=\s*(\S+)/) {
            $memory = getCanonicalSize($size.($size =~ /b$/i ? '' : 'B'), 1024);
        } elsif ($line =~ /^processors\s*=\s*(\d+)/) {
            $vcpu = $1;
        }
    }

    return ($memory, $vcpu);
}

1;
