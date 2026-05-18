package GLPI::Agent::Task::Inventory::Virtualization::HyperV;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Virtualization;

sub isEnabled {
    return OSNAME eq 'MSWin32';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $machine (_getVirtualMachines()) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub _getVirtualMachines {

    GLPI::Agent::Tools::Win32->require();

    my @machines;

    # Get host FQDN via WMI with fallback
    my $hostname;
    my @sysinfo = GLPI::Agent::Tools::Win32::getWMIObjects(
        class      => 'Win32_ComputerSystem',
        properties => [ qw/DNSHostName Domain PartOfDomain/ ]
    );
    if (@sysinfo) {
        my $obj = $sysinfo[0];
        if ($obj->{PartOfDomain} && $obj->{Domain}) {
            $hostname = $obj->{DNSHostName} . '.' . $obj->{Domain};
        } else {
            $hostname = $obj->{DNSHostName};
        }
    }
    if (!$hostname) {
        require Sys::Hostname;
        $hostname = Sys::Hostname::hostname();
    }

    # index memory, cpu and BIOS UUID information
    my %memory;
    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_MemorySettingData',
        properties => [ qw/InstanceID VirtualQuantity/ ]
    )) {
        my $id = $object->{InstanceID};
        next unless $id =~ /^Microsoft:([^\\]+)/;
        $memory{$1} = $object->{VirtualQuantity};
    }

    my %vcpu;
    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_ProcessorSettingData',
        properties => [ qw/InstanceID VirtualQuantity/ ]
    )) {
        my $id = $object->{InstanceID};
        next unless $id =~ /^Microsoft:([^\\]+)/;
        $vcpu{$1} = $object->{VirtualQuantity};
    }

    my %biosguid;
    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_VirtualSystemSettingData',
        properties => [ qw/InstanceID BIOSGUID/ ]
    )) {
        my $id = $object->{InstanceID};
        next unless $object->{BIOSGUID} && $id =~ /^Microsoft:([^\\]+)/;
        $biosguid{$1} = $object->{BIOSGUID};
        $biosguid{$1} =~ tr/{}//d;
    }

    # Index VHD sizes by file path using PowerShell Get-VHD
    # Size is in bytes, convert to MB
    my %vhd_size;
    my $script = 'Get-VM | Get-VMHardDiskDrive | ForEach-Object { Get-VHD $_.Path } | Select-Object Path, Size | ForEach-Object { Write-Output ($_.Path + "|" + $_.Size) }';
    for my $line (GLPI::Agent::Tools::Win32::runPowerShell(script => $script)) {
        next unless $line =~ /^(.+)\|(\d+)$/;
        my ($path, $size) = ($1, $2);
        $vhd_size{lc($path)} = int($size / 1024 / 1024);
    }

    my %drives;
    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_StorageAllocationSettingData',
        properties => [ qw/InstanceID HostResource ResourceType/ ]
    )) {
        next unless defined $object->{ResourceType} && $object->{ResourceType} == 31;
        next unless $object->{HostResource};
        my $id = $object->{InstanceID} // '';
        next unless $id =~ /^Microsoft:([^\\]+)/;
        my $vm_guid = $1;
        my $path = ref($object->{HostResource}) eq 'ARRAY'
                     ? $object->{HostResource}[0]
                     : $object->{HostResource};
        my $name = (split /[\\\/]/, $path)[-1];
        push @{$drives{$vm_guid}}, {
            VOLUMN => $path,
            TOTAL  => $vhd_size{lc($path)} // 0,
            LABEL  => $name,
        };
    }

    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_ComputerSystem',
        properties => [ qw/ElementName EnabledState Name InstallDate/ ]
    )) {
        # skip host as if has no InstallDate,
        # see https://docs.microsoft.com/en-us/windows/desktop/hyperv_v2/msvm-computersystem
        next unless $object->{InstallDate};

        my $status =
            $object->{EnabledState} == 2     ? STATUS_RUNNING  :
            $object->{EnabledState} == 3     ? STATUS_OFF      :
            $object->{EnabledState} == 32768 ? STATUS_PAUSED   :
            $object->{EnabledState} == 32769 ? STATUS_OFF      :
            $object->{EnabledState} == 32770 ? STATUS_BLOCKED  :
            $object->{EnabledState} == 32771 ? STATUS_BLOCKED  :
            $object->{EnabledState} == 32773 ? STATUS_BLOCKED  :
            $object->{EnabledState} == 32774 ? STATUS_SHUTDOWN :
            $object->{EnabledState} == 32776 ? STATUS_BLOCKED  :
            $object->{EnabledState} == 32777 ? STATUS_BLOCKED  :
                                               STATUS_OFF      ;
        my $machine = {
            SUBSYSTEM => 'MS HyperV',
            VMTYPE    => 'HyperV',
            STATUS    => $status,
            NAME      => $object->{ElementName},
            UUID      => $biosguid{$object->{Name}},
            MEMORY    => $memory{$object->{Name}},
            VCPU      => $vcpu{$object->{Name}},
            DRIVES    => $drives{$object->{Name}} // [],
            HOSTNAME  => $hostname,
        };

        push @machines, $machine;

    }

    return @machines;
}

1;
