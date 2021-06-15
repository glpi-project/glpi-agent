package FusionInventory::Agent::Task::Inventory::Win32::Environment;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools::Win32;

use constant    category    => "environment";

sub isEnabled {
    return 1;
}

sub isEnabledForRemote {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $object (getWMIObjects(
        class      => 'Win32_Environment',
        properties => [ qw/SystemVariable Name VariableValue/ ]
    )) {

        next unless $object->{SystemVariable};

        $inventory->addEntry(
            section => 'ENVS',
            entry   => {
                KEY => $object->{Name},
                VAL => $object->{VariableValue}
            }
        );
    }
}

1;
