package GLPI::Agent::Task::Inventory::Solaris::Controllers;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "controller";

sub isEnabled {
    return canRun('cfgadm');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @lines = getAllLines(
        command => 'cfgadm -s cols=ap_id:type:info',
        logger  => $logger,
    );
    return unless @lines;

    foreach my $line (@lines) {
        next if $line =~  /^Ap_Id/;
        next unless $line =~ /^(\S+)\s+(\S+)\s+(\S+)/;
        my $name = $1;
        my $type = $2;
        my $manufacturer = $3;
        $inventory->addEntry(
            section => 'CONTROLLERS',
            entry => {
                NAME         => $name,
                MANUFACTURER => $manufacturer,
                TYPE         => $type,
            }
        );
    }
}

1;
