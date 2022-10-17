package GLPI::Agent::Task::Inventory::Generic::PCI::Videos::Nvidia;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "video";

sub isEnabled {
    return
        canRun('nvidia-settings');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $videos = $inventory->getSection('VIDEOS') || [];

    foreach my $video (_getNvidiaVideos(logger => $logger)) {
        my ($current) = grep { _samePciSlot($_->{PCISLOT}, $video->{PCISLOT} // '') } @{$videos};
        if ($current) {
            $current->{NAME} = $video->{NAME} unless $current->{NAME} || !$video->{NAME};
            $current->{MEMORY} = $video->{MEMORY} if $video->{MEMORY};
            $current->{CHIPSET} = $video->{CHIPSET} unless $current->{CHIPSET};
            $current->{RESOLUTION} = $video->{RESOLUTION} if $video->{RESOLUTION};
        } else {
            $inventory->addEntry(
                section => 'VIDEOS',
                entry   => $video
            );
        }
    }
}

my $pcislot_re = qr/^(?:([0-9a-f]+):)?([0-9a-f]{2}):([0-9a-f]{2})\.([0-9a-f]+)$/i;
sub _samePciSlot {
    my ($first, $second) = @_;

    my @first  = $first  =~ $pcislot_re;
    my @second = $second =~ $pcislot_re;

    return hex($first[0] // 0) == hex($second[0] // 0)
        && hex($first[1]) == hex($second[1])
        && hex($first[2]) == hex($second[2])
        && hex($first[3]) == hex($second[3]) ? 1 : 0;
}

sub _updatePci {
    my ($hash) = @_;

    my $dom  = delete $hash->{PCIDOMAIN};
    my $bus  = delete $hash->{PCIBUS};
    my $dev  = delete $hash->{PCIDEVICE};
    my $func = delete $hash->{PCIFUNC};
    $hash->{PCISLOT} = sprintf("%02x:%02x.%x", $bus, $dev, $func)
        if defined($bus) && defined($dev) && defined($func);
    $hash->{PCISLOT} = sprintf("%04x:%s", $dom, $hash->{PCISLOT})
        if $dom;

    return $hash;
}

sub _getNvidiaGpus {
    my (%params) = (
        command => "nvidia-settings -t -c all -q gpus",
        @_
    );

    # Support test cases
    $params{file} .= ".gpus" if $params{file} && $params{gpus};

    my $gpus;

    foreach my $line (getAllLines(%params)) {
        if ($line =~ /^\s+\[(\d+)\]\s+\[(gpu:\d+)\]\s+\((.*)\)$/) {
            $gpus->{$1} = {
                NAME => $2,
                INFO => $3
            };
        }
    }

    return $gpus;
}


sub _getNvidiaVideos {
    my (%params) = @_;

    my @videos;

    my $gpus = _getNvidiaGpus(%params);
    foreach my $num (sort(keys(%{$gpus}))) {
        my $gpu = $gpus->{$num}->{NAME};
        my ($video, $xres, $yres);
        foreach my $line (getAllLines(
            command => "nvidia-settings -t -c :$num -q all",
            %params
        )) {
            if ($line =~ /^\s+ScreenPosition: x=\d+, y=\d+, width=(\d+), height=(\d+)$/) {
                $xres = $1;
                $yres = $2;
            } elsif ($line =~ /^Attributes queryable via .*:$num\[$gpu\]:/) {
                $video = { CHIPSET => $gpus->{$num}->{INFO} };
                $video->{RESOLUTION} = $xres.'x'.$yres if $xres && $yres;
                next;
            } elsif ($line =~ /^Attributes queryable via/) {
                push @videos, _updatePci($video) if $video;
                undef $video;
            }
            next unless defined($video);

            if ($line =~ /^\s+TotalDedicatedGPUMemory:\s+(\d+)/) {
                $video->{MEMORY} = $1;
            } elsif ($line =~ /^\s+PCIDomain:\s+(\d+)/) {
                $video->{PCIDOMAIN} = $1;
            } elsif ($line =~ /^\s+PCIBus:\s+(\d+)/) {
                $video->{PCIBUS} = $1;
            } elsif ($line =~ /^\s+PCIDevice:\s+(\d+)/) {
                $video->{PCIDEVICE} = $1;
            } elsif ($line =~ /^\s+PCIFunc:\s+(\d+)/) {
                $video->{PCIFUNC} = $1;
            } elsif ($line =~ /^\s+PCIID:\s+(\S+)/) {
                my ($vendor_id, $device_id) = map { sprintf("%04x", $_) } split(",", $1);
                $video->{PCIID} = "$vendor_id:$device_id";
                my $vendor = getPCIDeviceVendor(id => $vendor_id, logger => $params{logger});
                if ($vendor && exists($vendor->{devices}->{$device_id}->{name})) {
                    my $chipset = $vendor->{name} ? $vendor->{name}." " : "";
                    if ($vendor->{devices}->{$device_id}->{name} =~ /^(.*)\s+\[(.*)\]$/) {
                        $video->{CHIPSET} = $chipset.$1;
                        $chipset .= $2;
                    }
                    $video->{NAME} = $chipset;
                }
            }
        }
        push @videos, _updatePci($video) if $video;
    }

    return @videos;
}

1;
