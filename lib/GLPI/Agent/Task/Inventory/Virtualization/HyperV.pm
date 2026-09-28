package GLPI::Agent::Task::Inventory::Virtualization::HyperV;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network qw(alt2canonical);
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
    my %serial;
    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_VirtualSystemSettingData',
        properties => [ qw/InstanceID BIOSGUID BIOSSerialNumber/ ]
    )) {
        my $id = $object->{InstanceID};
        next unless $id =~ /^Microsoft:([^\\]+)/;
        my $vm_guid = $1;
        if ($object->{BIOSGUID}) {
            $biosguid{$vm_guid} = $object->{BIOSGUID};
            $biosguid{$vm_guid} =~ tr/{}//d;
        }
        $serial{$vm_guid} = $object->{BIOSSerialNumber}
            if $object->{BIOSSerialNumber};
    }

    my %networks;
    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'Msvm_SyntheticEthernetPortSettingData',
        properties => [ qw/InstanceID ElementName Address/ ]
    )) {
        my $id = $object->{InstanceID}
            or next;
        next unless $id =~ /^Microsoft:([^\\]+)/;
        my $vm_guid = $1;
        my $mac = alt2canonical($object->{Address})
            or next;
        push @{$networks{$vm_guid}}, {
            DESCRIPTION => $object->{ElementName} // 'Network Adapter',
            MACADDR     => $mac,
        };
    }
    # Fallback for Generation 1 VMs using legacy emulated adapters
    if (!%networks) {
        foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
            moniker    => 'winmgmts://./root/virtualization/v2',
            altmoniker => 'winmgmts://./root/virtualization',
            class      => 'Msvm_EmulatedEthernetPortSettingData',
            properties => [ qw/InstanceID ElementName Address/ ]
        )) {
            my $id = $object->{InstanceID}
                or next;
            next unless $id =~ /^Microsoft:([^\\]+)/;
            my $vm_guid = $1;
            my $mac = alt2canonical($object->{Address})
                or next;
            push @{$networks{$vm_guid}}, {
                DESCRIPTION => $object->{ElementName} // 'Network Adapter',
                MACADDR     => $mac,
            };
        }
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

            (my $ps_path = $path) =~ s/'/''/g;
            my ($size_bytes) = GLPI::Agent::Tools::Win32::runPowerShell(
                script   => "Get-VHD -Path '" . $ps_path . "' | Select-Object -ExpandProperty Size",
                TEMPLATE => 'get-vhd-size-XXXXXX',
                logger   => $logger,
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
                    # On Linux guests, this is the kernel release string
                    # (uname -r), not the distro version - see OSMajorVersion
                    # below for the real distro/product version. Kept as a
                    # fallback for VERSION and as the source for KERNEL_VERSION.
                    $kvp{$vm_guid}{OSVersion} = $data;
                } elsif ($name eq 'OSBuildNumber') {
                    # Genuine Windows build number on Windows guests; on Linux
                    # guests the KVP daemon repurposes this key for the same
                    # kernel release string as OSVersion. Either way it's the
                    # best source for KERNEL_VERSION, preferred over OSVersion.
                    $kvp{$vm_guid}{OSBuildNumber} = $data;
                } elsif ($name eq 'OSMajorVersion') {
                    # The real distro/product version on Linux (e.g. "9.8" for
                    # RHEL 9.8, from /etc/os-release VERSION_ID) - distinct
                    # from OSVersion/OSBuildNumber, which are kernel-shaped.
                    $kvp{$vm_guid}{OSMajorVersion} = $data;
                } elsif ($name eq 'OSMinorVersion') {
                    $kvp{$vm_guid}{OSMinorVersion} = $data;
                } elsif ($name eq 'FullyQualifiedDomainName') {
                    # This is the guest OS own hostname/FQDN, as reported by
                    # the guest itself via Integration Services - not the
                    # Hyper-V host's, nor the VM's display name (ElementName).
                    # Reported under OPERATINGSYSTEM.FQDN, mirroring how
                    # SOAP/VMware/Host.pm already reports the ESX guest's own
                    # hostname (VIRTUALMACHINES.HOSTNAME was tried and
                    # reverted from this same PR: a previous attempt reported
                    # the Hyper-V host's own FQDN there, which does not
                    # belong on a VM entry - this is a different, per-guest
                    # value using the already-accepted field for it).
                    $kvp{$vm_guid}{FQDN} = $data;
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
            $object->{EnabledState} == 9     ? STATUS_PAUSED   :
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
        $machine->{SERIAL}   = $serial{$object->{Name}}   if $serial{$object->{Name}};
        $machine->{NETWORKS} = $networks{$object->{Name}} if $networks{$object->{Name}};

        if ($extended > 1 && $drives{$object->{Name}} && @{$drives{$object->{Name}}}) {
            $machine->{DRIVES} = $drives{$object->{Name}};
        }
        if ($extended) {
            my $vm_kvp = $kvp{$object->{Name}};
            if ($vm_kvp) {
                $machine->{IPADDRESS} = $vm_kvp->{IPADDRESS}
                    if defined $vm_kvp->{IPADDRESS};
                # Also attach the resolved IP to the first network adapter so
                # GLPI can create the corresponding NetworkPort/IPAddress: the
                # flat VIRTUALMACHINES.IPADDRESS field has no consumer on the
                # server side, only NETWORKS[].IPADDRESS does. KVP only gives
                # one IP per VM, not per adapter, so we can't tell which NIC
                # it belongs to when there is more than one.
                if (defined $machine->{IPADDRESS} && $machine->{NETWORKS} && @{$machine->{NETWORKS}}) {
                    $machine->{NETWORKS}[0]{IPADDRESS} = $machine->{IPADDRESS};
                }
                if ($vm_kvp->{OSName} || $vm_kvp->{OSVersion} || $vm_kvp->{OSBuildNumber} || $vm_kvp->{OSMajorVersion} || $vm_kvp->{FQDN}) {
                    my $os = {};
                    $os->{NAME} = $vm_kvp->{OSName}
                        if !empty($vm_kvp->{OSName});

                    # Guest's own hostname/FQDN, mirroring how SOAP/VMware/Host.pm
                    # already reports it for ESX VMs (OPERATINGSYSTEM.FQDN).
                    $os->{FQDN} = $vm_kvp->{FQDN}
                        if !empty($vm_kvp->{FQDN});

                    # VERSION: prefer OSMajorVersion (the real distro/product
                    # version), falling back to OSVersion when it's missing -
                    # on Linux guests OSVersion is kernel-shaped, not ideal,
                    # but still better than leaving VERSION empty.
                    my $version = $vm_kvp->{OSMajorVersion};
                    if (!empty($version) && !empty($vm_kvp->{OSMinorVersion})
                        && index($version, $vm_kvp->{OSMinorVersion}) < 0) {
                        $version .= '.' . $vm_kvp->{OSMinorVersion};
                    }
                    $version = $vm_kvp->{OSVersion} if empty($version);
                    $os->{VERSION} = $version
                        if !empty($version);

                    # KERNEL_VERSION: prefer OSBuildNumber, falling back to
                    # OSVersion if that's the only kernel-shaped value we got.
                    my $kernel_version = !empty($vm_kvp->{OSBuildNumber})
                        ? $vm_kvp->{OSBuildNumber}
                        : $vm_kvp->{OSVersion};
                    $os->{KERNEL_VERSION} = $kernel_version
                        if !empty($kernel_version);

                    my $full_name = join(' ', grep { !empty($_) } $os->{NAME}, $os->{VERSION});
                    $os->{FULL_NAME} = $full_name
                        if $full_name;

                    $machine->{OPERATINGSYSTEM} = $os
                        if %$os;
                }
                $logger->debug2(
                    "Hyper-V: VM '$machine->{NAME}' KVP data: " .
                    "ip=" . ($machine->{IPADDRESS} // 'N/A') . ", " .
                    "fqdn=" . ($machine->{OPERATINGSYSTEM}{FQDN} // 'N/A') . ", " .
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
