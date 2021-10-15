package GLPI::Agent::Task::Inventory::AIX::Sounds;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::AIX;

use constant    category    => "sound";

sub isEnabled {
    return canRun('lsdev');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $sound (_getSounds(
        logger  => $logger
    )) {
        $inventory->addEntry(
            section => 'SOUNDS',
            entry   => $sound
        );
    }

}

sub _getSounds {
    my @adapters = getAdaptersFromLsdev(@_);

    my @sounds;
    foreach my $adapter (@adapters) {
        next unless $adapter->{DESCRIPTION} =~ /audio/i;
        push @sounds, {
            NAME        => $adapter->{NAME},
            DESCRIPTION => $adapter->{DESCRIPTION}
        };
    }

    return @sounds;
}

1;
