package FusionInventory::Agent::Task::Inventory::Virtualization::Wsl;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Virtualization;

our $runAfter = [ qw(
    FusionInventory::Agent::Task::Inventory::Win32::OS
    FusionInventory::Agent::Task::Inventory::Win32::CPU
    FusionInventory::Agent::Task::Inventory::Win32::Bios
)];

sub isEnabled {
    return $OSNAME eq "MSWin32" && canRun('wsl');
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
    FusionInventory::Agent::Tools::Win32->require();
    FusionInventory::Agent::Tools::Win32::Users->require();

    # Prepare vcpu, memory and a serial from still inventoried CPUS, HARDWARE & BIOS
    my $cpus = $params{inventory}->getSection('CPUS') // [{}];
    my $vcpu = 0;
    map { $vcpu += $_->{CORE} // 1 } @{$cpus};
    my $memory = $params{inventory}->getField('HARDWARE', 'MEMORY');
    my $serial = $params{inventory}->getField('BIOS', 'SSN') // '';
    my $other  = $params{inventory}->getField('BIOS', 'MSN') // '';
    $serial .= "/$other" if $other;

    # Get system build revision to handle default max memory with WSL2
    my $kernel_version = $params{inventory}->getField('OPERATINGSYSTEM', 'KERNEL_VERSION') // '';
    my ($build) = $kernel_version =~ /^\d+\.\d+\.(\d+)/;

    # Search users account for WSL instance
    foreach my $user (FusionInventory::Agent::Tools::Win32::Users::getSystemUsers()) {

        my $profile = FusionInventory::Agent::Tools::Win32::Users::getUserProfile($user->{SID})
            or next;

        my ($lxsskey, $userhive);
        unless ($profile->{LOADED}) {
            my $ntuserdat = $profile->{PATH}."/NTUSER.DAT";
            # This call involves we use cleanupPrivileges before leaving
            $userhive = FusionInventory::Agent::Tools::Win32::loadUserHive( sid => $user->{SID}, file => $ntuserdat );
        }
        $lxsskey = FusionInventory::Agent::Tools::Win32::getRegistryKey(path => "HKEY_USERS/$user->{SID}/SOFTWARE/Microsoft/Windows/CurrentVersion/Lxss/")
            or next;

        # Support WSL2 memory/vcpu configuration
        my ($usermem, $uservcpu);
        if (-e $profile->{PATH}."/.wslconfig") {
            ($usermem, $uservcpu) = _parseWslConfig(
                file    => $profile->{PATH}."/.wslconfig",
                %params
            );
        }

        foreach my $sub (keys(%{$lxsskey})) {
            # We will use install GUID as WSL instance UUID
            my ($uuid) = $sub =~ /^{(........-....-....-....-............)}\/$/
                or next;
            $uuid = uc($uuid);
            my $basepath = $lxsskey->{$sub}->{'/BasePath'}
                or next;
            my $distro = $lxsskey->{$sub}->{'/DistributionName'}
                or next;
            my $hostname = "$distro on $user->{NAME} account";

            my $version = "2";
            # Set computed UUID, hostname && S/N in WSL1 instance FS to support
            # agent run from the distribution
            if (-d $basepath."/rootfs/etc") {
                my $handle;
                if (open $handle, ">", $basepath."/rootfs/etc/inventory-uuid") {
                    print $handle "$uuid\n";
                    close($handle);
                }
                if (open $handle, ">", $basepath."/rootfs/etc/inventory-hostname") {
                    print $handle "$hostname\n";
                    close($handle);
                }
                if ($serial && open $handle, ">", $basepath."/rootfs/etc/inventory-serialnumber") {
                    print $handle "$serial\n";
                    close($handle);
                }
                $version = "1";
            }

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

    FusionInventory::Agent::Tools::Win32::cleanupPrivileges();

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
        if ($line =~ /^memory\s*=\s*(\S+)/) {
            $memory = getCanonicalSize($1.($1 =~ /b$/i ? '' : 'B'), 1024);
        } elsif ($line =~ /^processors\s*=\s*(\d+)/) {
            $vcpu = $1;
        }
    }

    return ($memory, $vcpu);
}

1;
