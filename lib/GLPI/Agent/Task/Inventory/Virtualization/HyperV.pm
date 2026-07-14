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

    foreach my $machine (_getVirtualMachines(%params)) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub _getVirtualMachines {
    my (%params) = @_;
    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    GLPI::Agent::Tools::Win32->require();

    my @machines;

    # Determine once whether GLPI supports extended VM fields:
    #   0 = basic inventory only
    #   1 = GLPI >= 10.0.25: IPADDRESS and OPERATINGSYSTEM supported
    #   2 = GLPI >= 12: DRIVES also supported (pending inventory_format PR)
    my $extended = 0;
    if ($inventory) {
        $extended = $inventory->supportsGlpiVersion('12')     ? 2 :
                    $inventory->supportsGlpiVersion('10.0.25') ? 1 : 0;
    }
    if ($extended >= 2) {
        $logger->debug("Hyper-V: GLPI supports extended VM fields (DRIVES, IPADDRESS, OPERATINGSYSTEM)")
            if $logger;
    } elsif ($extended == 1) {
        $logger->debug("Hyper-V: GLPI supports extended VM fields (IPADDRESS, OPERATINGSYSTEM)")
            if $logger;
    } else {
        $logger->debug("Hyper-V: GLPI version does not support extended VM fields (requires 10.0.25+), collecting basic inventory only")
            if $logger;
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

    my %drives;
    my %kvp;
    if ($extended > 1) {
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
            # WMI may return strings as raw UTF-8 bytes without Perl's UTF-8 flag set.
            # Decoding ensures non-ASCII characters in any locale serialize correctly to JSON.
            utf8::decode($path) if $path && !utf8::is_utf8($path);

            # Skip file types unsupported by Get-VHD (ISOs, virtual floppy disks)
            if ($path =~ /\.(?:iso|vfd)$/i) {
                $logger->debug2("Hyper-V: skipping unsupported file type '$path'")
                    if $logger;
                next;
            }

            my ($size_bytes) = GLPI::Agent::Tools::Win32::runPowerShell(
                script => 'Get-VHD -Path "' . $path . '" | Select-Object -ExpandProperty Size'
            );
            if (!$size_bytes) {
                # Distinguish between avhdx (checkpoint) and regular vhdx
                if ($path =~ /\.avhdx$/i) {
                    $logger->debug("Hyper-V: could not retrieve size for checkpoint '$path' - checkpoints may require the VM to be running or merged")
                        if $logger;
                } else {
                    $logger->warning("Hyper-V: could not retrieve size for VHD '$path' via Get-VHD (check path, permissions or VM state)")
                        if $logger;
                }
            } else {
                $logger->debug2("Hyper-V: VHD '$path' size = $size_bytes bytes")
                    if $logger;
            }
            my $size_mb = $size_bytes ? int($size_bytes / 1024 / 1024) : 0;
            push @{$drives{$vm_guid}}, {
                VOLUMN => $path,
                TOTAL  => $size_mb,
            };
        }
    }
    if ($extended) {
        foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
            moniker    => 'winmgmts://./root/virtualization/v2',
            altmoniker => 'winmgmts://./root/virtualization',
            class      => 'Msvm_KvpExchangeComponent',
            properties => [ qw/SystemName GuestIntrinsicExchangeItems/ ]
        )) {
            my $vm_guid = $object->{SystemName}
                or next;
            my $items   = $object->{GuestIntrinsicExchangeItems}
                or next;
            $items = [$items] unless ref($items) eq 'ARRAY';
            foreach my $xml (@$items) {
                $xml =~ s/&quot;/"/g;
                my ($name) = $xml =~ m{<PROPERTY NAME="Name"[^>]*><VALUE>([^<]*)</VALUE>};
                my ($data) = $xml =~ m{<PROPERTY NAME="Data"[^>]*><VALUE>([^<]*)</VALUE>};
                next if empty($name) || empty($data);
                if ($name eq 'NetworkAddressIPv4') {
                    my ($ip) = split(/;/, $data);
                    if ($ip && $ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                        $kvp{$vm_guid}{IPADDRESS} = $ip;
                    } else {
                        $kvp{$vm_guid}{IP_DEPRECATED} = 1;
                    }
                } elsif ($name eq 'OSName') {
                    $kvp{$vm_guid}{OSName} = $data;
                } elsif ($name eq 'OSVersion') {
                    $kvp{$vm_guid}{OSVersion} = $data;
                }
            }
        }

        if (%kvp) {
            $logger->debug2("Hyper-V: KVP guest data found for " . scalar(keys %kvp) . " VM(s)")
                if $logger;
        } else {
            $logger->debug("Hyper-V: no KVP guest data found - Hyper-V Integration Services may not be installed in guest VMs")
                if $logger;
        }

        # Fallback for hosts where KVP NetworkAddressIPv4 keys are deprecated.
        # Msvm_GuestNetworkAdapterConfiguration provides IP addresses in newer Hyper-V versions.
        my $need_fallback = grep { $_->{IP_DEPRECATED} } values %kvp;
        if ($need_fallback) {
            $logger->debug("Hyper-V: KVP IP keys deprecated, falling back to Msvm_GuestNetworkAdapterConfiguration")
                if $logger;
            foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
                moniker    => 'winmgmts://./root/virtualization/v2',
                class      => 'Msvm_GuestNetworkAdapterConfiguration',
                properties => [ qw/InstanceID IPAddresses/ ]
            )) {
                my $instance_id = $object->{InstanceID}
                    or next;
                my $ips         = $object->{IPAddresses}
                    or next;
                my ($vm_guid)   = $instance_id =~ m{GuestNetwork\\([^\\]+)}i;
                next unless $vm_guid;
                next if defined $kvp{$vm_guid}{IPADDRESS};
                $ips = [$ips] unless ref($ips) eq 'ARRAY';
                for my $ip (@$ips) {
                    if ($ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                        $kvp{$vm_guid}{IPADDRESS} = $ip;
                        last;
                    }
                }
            }
        }
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

        $logger->debug2("Hyper-V: found VM '$object->{ElementName}' (GUID: $object->{Name}), status=$status")
            if $logger;

        my $machine = {
            SUBSYSTEM => 'MS HyperV',
            VMTYPE    => 'HyperV',
            STATUS    => $status,
            NAME      => $object->{ElementName},
            UUID      => $biosguid{$object->{Name}},
            MEMORY    => $memory{$object->{Name}},
            VCPU      => $vcpu{$object->{Name}},
        };

        if ($extended > 1) {
            $machine->{DRIVES} = $drives{$object->{Name}} // [];
        }
        if ($extended) {
            my $vm_kvp = $kvp{$object->{Name}};
            if ($vm_kvp) {
                $machine->{IPADDRESS} = $vm_kvp->{IPADDRESS}
                    if defined $vm_kvp->{IPADDRESS};
                if ($vm_kvp->{OSName} || $vm_kvp->{OSVersion}) {
                    my $full_name = join(' ',
                        grep { !empty($_) }
                        $vm_kvp->{OSName}, $vm_kvp->{OSVersion}
                    );
                    $machine->{OPERATINGSYSTEM} = { FULL_NAME => $full_name }
                        if $full_name;
                }
                $logger->debug2(
                    "Hyper-V: VM '$machine->{NAME}' KVP data: " .
                    "ip=" . ($machine->{IPADDRESS} // 'N/A') . ", " .
                    "os=" . ($machine->{OPERATINGSYSTEM}{FULL_NAME} // 'N/A')
                ) if $logger;
            } else {
                $logger->debug2("Hyper-V: VM '$machine->{NAME}': no KVP guest data (Integration Services may not be installed)")
                    if $logger;
            }
        }

        push @machines, $machine;
    }

    $logger->debug("Hyper-V: inventory complete, " . scalar(@machines) . " virtual machine(s) found")
        if $logger;

    return @machines;
}

1;
