package GLPI::Agent::Task::Inventory::AIX::Slots;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::AIX;

use constant    category    => "slot";

sub isEnabled {
    return canRun('lsdev');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $slot (_getSlots(
        command => 'lsdev -Cc bus -F "name:description"',
        logger  => $logger
    )) {
        $inventory->addEntry(
            section => 'SLOTS',
            entry   => $slot
        );
    }
}

sub _getSlots {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    # index description by AX field from VPD infos
    my %description =
        map  { $_->{AX} => $_->{YL} }
        grep { $_->{AX} && $_->{YL} }
        getLsvpdInfos(logger => $params{logger});

    my @slots;
    foreach my $line (@lines) {
        my ($name, $designation, $description) = split(":", $line);
        $description = $description{$name} if $name && !$description && $description{$name};
        next unless defined($name) && defined($designation) && defined($description);

        push @slots, {
            NAME        => $name,
            DESIGNATION => $designation,
            DESCRIPTION => $description,
        };
    }

    return @slots;
}

1;
