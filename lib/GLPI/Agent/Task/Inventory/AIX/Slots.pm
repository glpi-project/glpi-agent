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

    # index VPD infos by AX field
    my %infos =
        map  { $_->{AX} => $_ }
        grep { $_->{AX} }
        getLsvpdInfos(logger => $logger);

    foreach my $slot (_getSlots(
        command => 'lsdev -Cc bus -F "name:description"',
        logger  => $logger
    )) {

        $slot->{DESCRIPTION} = $infos{$slot->{NAME}}->{YL}
            if $infos{$slot->{NAME}};

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

    my @slots;
    foreach my $line (@lines) {
        next unless $line =~ /^(.+):(.+)/;

        push @slots, {
            NAME        => $1,
            DESIGNATION => $2,
        };
    }

    return @slots;
}

1;
