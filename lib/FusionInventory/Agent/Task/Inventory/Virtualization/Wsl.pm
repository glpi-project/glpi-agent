package FusionInventory::Agent::Task::Inventory::Virtualization::Wsl;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Win32;
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

sub  _getUpdatedWsl {
    my (%params) = @_;

    my $wsl = {
        NAME        => $params{hostname},
        VMTYPE      => "WSL",
        SUBSYSTEM   => "WSL",
        VCPU        => $params{vcpu},
        MEMORY      => $params{memory},
        UUID        => $params{uuid},
    };

    my $handle = getFileHandle(
        command => "runas /user:$params{user} \"wsl -l -v\"",
        %params
    );
    return $wsl unless $handle;

    my @machines;
    my $header;

    foreach my $line (<$handle>) {
        # wsl command output seems to be UTF-16 but we can't decode it as expected
        # so we just need to clean it up
        $line = getSanitizedString($line)
            or next;
        next unless length($line);

        my ($select, $name, $state, $version) = $line =~ /^(.)\s+(\w+)\s+(\w+)\s+(\w+)/
            or next;

        # Handle header
        unless ($header) {
            last unless $name && $name eq 'NAME';
            $header++;
            next;
        }

        next unless $name eq $params{name};

        $wsl->{STATUS} = $state eq 'Running' ? STATUS_RUNNING :
                         $state eq 'Stopped' ? STATUS_OFF     :
                                               STATUS_OFF     ;
        last;
    }
    close $handle;

    return $wsl;
}

sub  _getUsersWslInstances {
    my (%params) = @_;

    my @machines;

    # Prepare vcpu & memory from still inventoried CPUS & HARDWARE
    my $cpus = $params{inventory}->getSection('CPUS');
    my $vcpu = 0;
    map { $vcpu += $_->{THREAD} // $_->{CORE} // 0 } @{$cpus};
    my $memory = $params{inventory}->getField('HARDWARE', 'MEMORY');
    my $serial = $params{inventory}->getField('BIOS', 'SSN')
        || $params{inventory}->getField('BIOS', 'MSN');

    my $query =
        "SELECT * FROM Win32_UserAccount " .
        "WHERE LocalAccount='True' AND Disabled='False' and Lockout='False'";

    foreach my $object (getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        query      => $query,
        properties => [ qw/Name SID FullName Domain/ ])
    ) {
        my $user = $object->{FullName} || $object->{Name}
            or next;
        my $sid = $object->{SID}
            or next;
        my $domain = $object->{Domain}
            or next;

        my $lxsspath = "HKEY_USERS/$sid/SOFTWARE/Microsoft/Windows/CurrentVersion/Lxss/";
        my $lxsskey = getRegistryKey( path => $lxsspath )
            or next;
        foreach my $sub (keys(%{$lxsskey})) {
            # We will use install GUID as WSL instance UUID
            my ($uuid) = $sub =~ /^{(........-....-....-....-............)}\/$/
                or next;
            my $basepath = $lxsskey->{$sub}->{'/BasePath'}
                or next;
            my $distro = $lxsskey->{$sub}->{'/DistributionName'}
                or next;
            my $hostname = $user."'s ".$distro;

            my $wsl = _getUpdatedWsl(
                hostname    => $hostname,
                name        => $distro,
                vcpu        => $vcpu,
                memory      => $memory,
                user        => "$domain\\$object->{Name}",
                uuid        => $uuid,
                %params
            );

            # Set computed UUID, hostname && S/N in instance FS in the case the agent
            # will also be run from the distribution
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

            push @machines, $wsl;
        }
    }

    return @machines;
}

1;
