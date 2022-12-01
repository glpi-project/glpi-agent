package GLPI::Agent::Task::Inventory::HPUX::Slots;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "slot";

sub isEnabled {
    return canRun('ioscan');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $type (qw/ioa ba/) {
        foreach my $slot (_getSlots(
            command => "ioscan -kFC $type",
            logger  => $logger
        )) {
            $inventory->addEntry(
                section => 'SLOTS',
                entry   => $slot
            );
        }
    }
}

sub _getSlots {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @slots;
    foreach my $line (@lines) {
        my @info = split(/:/, $line);
        push @slots, {
            NAME        => $info[9].$info[10],
            DESIGNATION => $info[13],
            DESCRIPTION => $info[17],
        };
    }

    return @slots;
}

1;
