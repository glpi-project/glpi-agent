package GLPI::Agent::Task::Inventory::Generic::Dmidecode::Slots;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "slot";

my %status = (
    'Unknown'   => undef,
    'In Use'    => 'used',
    'Available' => 'free'
);

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $slots = _getSlots(logger => $logger);

    return unless $slots;

    foreach my $slot (@$slots) {
        $inventory->addEntry(
            section => 'SLOTS',
            entry   => $slot
        );
    }
}

sub _getSlots {
    my $infos = getDmidecodeInfos(@_);

    return unless $infos->{9};

    my $slots;
    foreach my $info (@{$infos->{9}}) {
        my $slot = {
            DESCRIPTION => $info->{'Type'},
            DESIGNATION => $info->{'ID'},
            NAME        => $info->{'Designation'},
            STATUS      => $info->{'Current Usage'} ?
                $status{$info->{'Current Usage'}} : undef,
        };

        push @$slots, $slot;
    }

    return $slots;
}

1;
