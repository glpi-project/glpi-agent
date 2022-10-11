package GLPI::Agent::Task::Inventory::Generic::PCI::Videos;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;
use GLPI::Agent::Tools::Unix;

use constant    category    => "video";

sub isEnabled {
    # windows has dedicated module
    return
        OSNAME ne 'MSWin32';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $video (_getVideos(logger => $logger)) {
        $inventory->addEntry(
            section => 'VIDEOS',
            entry   => $video
        );
    }
}

sub _getVideos {
    my (%params) = @_;

    my @videos;

    foreach my $device (getPCIDevices(%params)) {
        next unless $device->{NAME} =~ /graphics|vga|video|display|3D controller/i;

        my ($vendor_id, $device_id) = split (/:/, $device->{PCIID});

        my ($chipset, $name) = $device->{MANUFACTURER} =~ /^(.*)\s+\[(.*)\]$/;
        my $vendor = getPCIDeviceVendor(id => $vendor_id, @_);
        ($name, $chipset) = $vendor->{devices}->{$device_id}->{name} =~ /^(.*)\s+\[(.*)\]$/
            if !$chipset && $vendor && exists($vendor->{devices}->{$device_id}->{name});

        my $manufacturer;
        if ($device->{PCISUBSYSTEMID}) {
            my ($vendor_id) = split (/:/, $device->{PCISUBSYSTEMID});
            my $vendor = getPCIDeviceVendor(id => $vendor_id, @_);
            $manufacturer = $vendor->{name} if $vendor;
            $name = $manufacturer.' '.$name if $manufacturer && $name;
        }

        my $video = {
            PCIID   => $device->{PCIID},
            PCISLOT => $device->{PCISLOT},
            CHIPSET => $chipset || $device->{NAME},
            NAME    => $name || $device->{MANUFACTURER}
        };

        $video->{MEMORY} = $device->{MEMORY} if $device->{MEMORY};
        push @videos, $video;
    }

    # Try to catch resolution with standard X11 clients if only one card is detected
    if (@videos == 1) {
        my ($xauth, $resolution);
        unless ($ENV{XAUTHORITY} || $params{file}) {
            # Setup environment to be trusted by current running X server
            $xauth = getXAuthorityFile(%params);
            $ENV{XAUTHORITY} = $xauth if $xauth;
        }
        if (canRun("xrandr") || $params{xrandr}) {
            $params{file} .= ".xrandr" if $params{xrandr};
            my ($xres, $yres) = getFirstMatch(
                command => "xrandr -d :0",
                pattern => qr/^Screen.*current (\d+) x (\d+),/,
                %params
            );
            $resolution = $xres.'x'.$yres if $xres && $yres;
        }
        if (!$resolution && (canRun("xdpyinfo") || $params{xdpyinfo})) {
            $params{file} .= ".xdpyinfo" if $params{xdpyinfo};
            ($resolution) = getFirstMatch(
                command => "xdpyinfo -d :0",
                pattern => qr/^\s+dimensions:\s+(\d+x\d+)\s+pixels/,
                %params
            );
        }
        $videos[0]->{RESOLUTION} = $resolution
            if $resolution;

        # Cleanup environment
        delete $ENV{XAUTHORITY} if $xauth;
    }

    return @videos;
}

1;
