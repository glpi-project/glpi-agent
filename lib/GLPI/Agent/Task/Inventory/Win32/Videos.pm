package GLPI::Agent::Task::Inventory::Win32::Videos;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;
use GLPI::Agent::Tools::Win32;

use constant    category    => "video";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my %seen;
    my $inventory = $params{inventory};

    foreach my $video (_getVideos(logger => $params{logger})) {
        next unless $video->{NAME};

        # avoid duplicates
        next if $seen{$video->{NAME}}++;

        $inventory->addEntry(
            section => 'VIDEOS',
            entry   => $video
        );
    }
}

sub _getVideos {
    my (%params) = @_;

    my @videos;

    foreach my $object (getWMIObjects(
        class      => 'Win32_VideoController',
        properties => [ qw/
            CurrentHorizontalResolution CurrentVerticalResolution VideoProcessor
            AdapterRAM Name PNPDeviceID
        / ],
        %params
    )) {
        next unless $object->{Name};

        # Exclude Remote Display Adapter (RDP) across all languages by checking PNPDeviceID
        next if $object->{PNPDeviceID} && $object->{PNPDeviceID} =~ /REMOTEDISPLAY/i;

        my $video = {
            CHIPSET => $object->{VideoProcessor},
            NAME    => $object->{Name},
        };
        $video->{MEMORY} = $object->{AdapterRAM} if $object->{AdapterRAM} && $object->{AdapterRAM} > 0;

        if ($object->{CurrentHorizontalResolution}) {
            $video->{RESOLUTION} =
                $object->{CurrentHorizontalResolution} .
                "x" .
                $object->{CurrentVerticalResolution};
        }

        if ($object->{PNPDeviceID}) {
            my $pnp_id = $object->{PNPDeviceID};
            $pnp_id =~ s{\\}{/}g;
            my $enum_key = getRegistryKey(
                path     => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Enum/$pnp_id",
                required => [ qw/LocationInformation/ ]
            );
            if ($enum_key && $enum_key->{"/LocationInformation"}) {
                my $loc = $enum_key->{"/LocationInformation"};
                if ($loc =~ /\((\d+),\s*(\d+),\s*(\d+)\)$/ || $loc =~ /PCI bus (\d+),\s*device (\d+),\s*function (\d+)/i) {
                    $video->{PCISLOT} = sprintf("%02x:%02x.%x", $1, $2, $3);
                }
            }
        }

        my $pnpdeviceid = _pnpdeviceid($object->{PNPDeviceID});

        my $found_specific_driver = 0;

        if ($pnpdeviceid) {
            # Try to get memory from registry
            my $videokey = getRegistryKey(
                path     => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Class/{4d36e968-e325-11ce-bfc1-08002be10318}",
                # Important for remote inventory optimization
                required => [ qw/HardwareInformation.MemorySize HardwareInformation.qwMemorySize MatchingDeviceId/ ],
                maxdepth => 2,
            );
            if ($videokey) {
                foreach my $subkey (keys(%{$videokey})) {
                    next unless $subkey =~ m{/$} && defined($videokey->{$subkey}) && ref($videokey->{$subkey});
                    my $thispnpdeviceid = _pnpdeviceid($videokey->{$subkey}->{"/MatchingDeviceId"})
                        or next;
                    next unless $thispnpdeviceid eq $pnpdeviceid;
                    $found_specific_driver = 1;

                    if (defined($videokey->{$subkey}->{"/HardwareInformation.qwMemorySize"})) {
                        my $memorysize = $videokey->{$subkey}->{"/HardwareInformation.qwMemorySize"} =~ /^\d+$/ ?
                            int($videokey->{$subkey}->{"/HardwareInformation.qwMemorySize"})
                            : unpack("Q", $videokey->{$subkey}->{"/HardwareInformation.qwMemorySize"});
                        $video->{MEMORY} = $memorysize if $memorysize && $memorysize > 0;
                        last;
                    } elsif (defined($videokey->{$subkey}->{"/HardwareInformation.MemorySize"})) {
                        my $memorysize = $videokey->{$subkey}->{"/HardwareInformation.MemorySize"} =~ /^0x/ ?
                            hex2dec($videokey->{$subkey}->{"/HardwareInformation.MemorySize"})
                            : $videokey->{$subkey}->{"/HardwareInformation.MemorySize"} =~ /^\d+$/ ?
                            int($videokey->{$subkey}->{"/HardwareInformation.MemorySize"})
                            : unpack("L", $videokey->{$subkey}->{"/HardwareInformation.MemorySize"});
                        $video->{MEMORY} = $memorysize if $memorysize && $memorysize > 0;
                        last;
                    }
                }
            }
        }

        # Fallback for generic drivers (e.g. Microsoft Basic Display Adapter)
        # If no specific registry key was found matching the PNPDeviceID, it means a generic driver is in use.
        if (!$found_specific_driver && !empty($object->{PNPDeviceID})) {
            if ($object->{PNPDeviceID} =~ /PCI\\VEN_(\S{4})&DEV_(\S{4})/i) {
                my $vendor_id = lc($1);
                my $device_id = lc($2);
                my $vendor = getPCIDeviceVendor(id => $vendor_id, %params);
                if ($vendor && $vendor->{devices}->{$device_id}) {
                    my $device_name = $vendor->{devices}->{$device_id}->{name} // '';
                    my $vendor_name = $vendor->{name} // '';
                    my ($pci_name, $pci_chipset);
                    if ($device_name =~ /^(.*)\s+\[(.*)\]$/) {
                        $pci_name = $1;
                        $pci_chipset = $2;
                    }
                    if ($object->{PNPDeviceID} =~ /SUBSYS_\S{4}(\S{4})/i) {
                        my $subvendor_id = lc($1);
                        if ($subvendor_id ne '0000') {
                            my $subvendor = getPCIDeviceVendor(id => $subvendor_id, %params);
                            my $manufacturer = $subvendor ? $subvendor->{name} : '';
                            $pci_name = $manufacturer.' '.$pci_name if $manufacturer && $pci_name;
                        }
                    }
                    $video->{CHIPSET} = $pci_chipset || $device_name;
                    $video->{NAME}    = $pci_name || $vendor_name;
                }
            }
        }

        $video->{MEMORY} = int($video->{MEMORY} / (1024 * 1024))
            if $video->{MEMORY};

        push @videos, $video;
    }

    return @videos;
}

sub _pnpdeviceid {
    my ($pnpdeviceid) = @_;

    return unless $pnpdeviceid;

    my @parts = split('&', $pnpdeviceid);
    return unless @parts > 1;

    my @found = grep { /^(pci\\ven|dev)_/i } @parts;
    return unless @found == 2;

    return lc(join('&', @found));
}

1;
