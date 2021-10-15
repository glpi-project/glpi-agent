package GLPI::Agent::Task::Inventory::AIX::Videos;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::AIX;

use constant    category    => "video";

sub isEnabled {
    return canRun('lsdev');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $video (_getVideos(
        logger  => $logger
    )) {
        $inventory->addEntry(
            section => 'VIDEOS',
            entry   => $video
        );
    }
}

sub _getVideos {
    my @adapters = getAdaptersFromLsdev(@_);

    my @videos;
    foreach my $adapter (@adapters) {
        next unless $adapter->{DESCRIPTION} =~ /graphics|vga|video/i;
        push @videos, {
            NAME => $adapter->{NAME},
        };
    }

    return @videos;
}

1;
