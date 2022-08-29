package GLPI::Agent::Task::Inventory::Win32::Videos;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
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

        my $video = {
            CHIPSET => $object->{VideoProcessor},
            MEMORY  => $object->{AdapterRAM},
            NAME    => $object->{Name},
        };

        if ($object->{CurrentHorizontalResolution}) {
            $video->{RESOLUTION} =
                $object->{CurrentHorizontalResolution} .
                "x" .
                $object->{CurrentVerticalResolution};
        }

        my $pnpdeviceid = _pnpdeviceid($object->{PNPDeviceID});
        if ($pnpdeviceid) {
            # Try to get memory from registry
            my $videokey = getRegistryKey(
                path     => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Class/{4d36e968-e325-11ce-bfc1-08002be10318}",
                # Important for remote inventory optimization
                required => [ qw/HardwareInformation.MemorySize MatchingDeviceId/ ],
                maxdepth => 2,
            );
            if ($videokey) {
                foreach my $subkey (keys(%{$videokey})) {
                    next unless $subkey =~ m{/$} && defined($videokey->{$subkey});
                    my $thispnpdeviceid = _pnpdeviceid($videokey->{$subkey}->{"/MatchingDeviceId"})
                        or next;
                    next unless $thispnpdeviceid eq $pnpdeviceid;
                    next unless defined($videokey->{$subkey}->{"/HardwareInformation.qwMemorySize"});
                    my $memorysize = unpack("Q", $videokey->{$subkey}->{"/HardwareInformation.qwMemorySize"});
                    $video->{MEMORY} = $memorysize;
                    last;
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
