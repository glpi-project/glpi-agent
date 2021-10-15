package GLPI::Agent::Task::Inventory::BSD::CPU;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "cpu";

sub isEnabled {
    return canRun('dmidecode');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $speed;
    my $hwModel = getFirstLine(command => 'sysctl -n hw.model');
    if ($hwModel =~ /([\.\d]+)GHz/) {
        $speed = $1 * 1000;
    }

    foreach my $cpu (getCpusFromDmidecode()) {
        $cpu->{SPEED} = $speed;
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }

}

1;
