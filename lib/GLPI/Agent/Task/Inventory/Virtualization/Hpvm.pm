package FusionInventory::Agent::Task::Inventory::Virtualization::Hpvm;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use XML::TreePP;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Virtualization;

sub isEnabled {
    return canRun('hpvmstatus');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $machine (_getMachines(
        command => 'hpvmstatus -X', logger => $logger
    )) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub _getMachines {
    my $xml = getAllLines(@_);
    return unless $xml;

    my $tpp = XML::TreePP->new();
    my $data = $tpp->parse($xml);
    my $mvs = $data->{pman}->{virtual_machine};

    my %units = (
        'MB' => 1,
        'GB' => 1024,
    );

    my %status = (
        'On'        => STATUS_RUNNING,
        'Off'       => STATUS_OFF,
        'Invalid'   => STATUS_CRASHED,
    );

    my @machines;
    foreach my $name (keys %$mvs) {
        my $info = $mvs->{$name};

        my $machine = {
            MEMORY    => $info->{memory}->{total}->{content} *
                         $units{$info->{memory}->{total}->{unit}},
            NAME      => $name,
            UUID      => $info->{uuid},
            STATUS    => $status{$info->{vm_state}},
            SUBSYSTEM => "HPVM",
            VMTYPE    => "HPVM",
            VCPU      => $info->{vcpu_number},
        };

        push @machines, $machine;
    }

    return @machines;
}

1;
