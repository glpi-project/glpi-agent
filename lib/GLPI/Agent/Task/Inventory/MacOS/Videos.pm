package GLPI::Agent::Task::Inventory::MacOS::Videos;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::MacOS;

use constant    category    => "video";

sub isEnabled {
    return canRun('/usr/sbin/system_profiler');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $video (_getVideoCards(logger => $logger)) {
        $inventory->addEntry(
            section => 'VIDEOS',
            entry   => $video,
        );
    }
}

sub _getVideoCards {
    my (%params) = @_;

    my $infos = getSystemProfilerInfos(
        type   => 'SPDisplaysDataType',
        logger => $params{logger},
        file   => $params{file}
    );

    my @videos;

    foreach my $videoName (keys %{$infos->{'Graphics/Displays'}}) {
        my $videoCardInfo = $infos->{'Graphics/Displays'}->{$videoName};

        my $memory = getCanonicalSize($videoCardInfo->{'VRAM (Total)'} ||
            $videoCardInfo->{'VRAM (Dynamic, Max)'}, 1024);
        $memory =~ s/\ .*//g if $memory;

        my $video = {
            CHIPSET    => $videoCardInfo->{'Chipset Model'},
            MEMORY     => $memory,
            NAME       => $videoName
        };

        foreach my $displayName (keys %{$videoCardInfo->{Displays}}) {
            next if $displayName eq 'Display Connector';
            next if $displayName eq 'Display';
            my $displayInfo = $videoCardInfo->{Displays}->{$displayName};

            my $resolution = $displayInfo->{Resolution};
            if ($resolution) {
                my ($x,$y) = $resolution =~ /(\d+) *x *(\d+)/;
                $resolution = $x.'x'.$y if $x && $y;
            }

            # Set first found resolution on associated video card
            $video->{RESOLUTION} = $resolution
                if $resolution && !$video->{RESOLUTION};
        }

        $video->{PCISLOT} = $videoCardInfo->{Bus}
            if defined($videoCardInfo->{Bus});
        $video->{PCISLOT} = $videoCardInfo->{Slot}
            if defined($videoCardInfo->{Slot});

        push @videos, $video;
    }

    return @videos;
}

1;
