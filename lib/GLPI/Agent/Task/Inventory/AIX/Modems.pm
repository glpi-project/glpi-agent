package GLPI::Agent::Task::Inventory::AIX::Modems;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::AIX;

use constant    category    => "modem";

sub isEnabled {
    return canRun('lsdev');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $modem (_getModems(
        logger  => $logger,
    )) {
        $inventory->addEntry(
            section => 'MODEMS',
            entry   => $modem,
        );
    }
}

sub _getModems {
    my @adapters = getAdaptersFromLsdev(@_);

    my @modems;
    foreach my $adapter (@adapters) {
        next unless $adapter->{DESCRIPTION} =~ /modem/i;
        push @modems, {
            NAME        => $adapter->{NAME},
            DESCRIPTION => $adapter->{DESCRIPTION},
        };
    }

    return @modems;
}

1;
