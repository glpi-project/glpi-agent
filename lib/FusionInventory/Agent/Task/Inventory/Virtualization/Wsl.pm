package FusionInventory::Agent::Task::Inventory::Virtualization::Wsl;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Win32;
use FusionInventory::Agent::Tools::Win32::Users;
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

    # Prepare vcpu, memory and a serial from still inventoried CPUS, HARDWARE & BIOS
    # TODO this is wrong for vcpu & memory as they can be set in a config file
    my $cpus = $params{inventory}->getSection('CPUS');
    my $vcpu = 0;
    map { $vcpu += ($_->{THREAD} // 1) * ($_->{CORE} // 1) } @{$cpus};
    my $memory = $params{inventory}->getField('HARDWARE', 'MEMORY');
    my $serial = $params{inventory}->getField('BIOS', 'SSN') // '';
    my $other  = $params{inventory}->getField('BIOS', 'MSN') // '';
    $serial .= "/$other" if $other;

    # Search users account for WSL instance
    foreach my $user (getSystemUsers()) {

        my $profile = getUserProfile($user->{SID})
            or next;

        my ($lxsskey, $userhive);
        unless ($profile->{LOADED}) {
            my $ntuserdat = $profile->{PATH}."/NTUSER.DAT";
            # This call involves we use cleanupPrivileges before leaving
            $userhive = loadUserHive( sid => $user->{SID}, file => $ntuserdat );
        }
        $lxsskey = getRegistryKey(path => "HKEY_USERS/$user->{SID}/SOFTWARE/Microsoft/Windows/CurrentVersion/Lxss/")
            or next;

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

            my $wsl = {
                NAME        => $hostname,
                VMTYPE      => "WSL",
                SUBSYSTEM   => "WSL",
                VCPU        => $vcpu,
                MEMORY      => $memory,
                UUID        => $uuid,
            };

            # Set computed UUID, hostname && S/N in WSL1 instance FS to support
            # agent run from the distribution
            if (-d $basepath."/rootfs/etc") {
                if (open UUID, ">", $basepath."/rootfs/etc/inventory-uuid") {
                    print UUID "$uuid\n";
                    close(UUID);
                }
                if (open HOSTNAME, ">", $basepath."/rootfs/etc/inventory-hostname") {
                    print HOSTNAME "$hostname\n";
                    close(HOSTNAME);
                }
                if ($serial && open SERIAL, ">", $basepath."/rootfs/etc/inventory-serialnumber") {
                    print SERIAL "$serial\n";
                    close(SERIAL);
                }
            }

            push @machines, $wsl;
        }

        # Free memory before leaving the block to avoid a Win32API error while
        # userhive is automatically unloaded
        undef $lxsskey if $userhive;
    }

    cleanupPrivileges();

    return @machines;
}

1;
