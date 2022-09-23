package GLPI::Agent::Task::Inventory::Virtualization::Hpvm;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Virtualization;
use GLPI::Agent::XML;

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

    my $data = GLPI::Agent::XML->new(string => $xml)->dump_as_hash();
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
