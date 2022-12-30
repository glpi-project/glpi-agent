package GLPI::Agent::Task::Inventory::Linux::m68k::CPU;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Linux;

use constant    category    => "cpu";

sub isEnabled {
    return canRead('/proc/cpuinfo');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $cpu (_getCPUsFromProc(
        logger => $logger, file => '/proc/cpuinfo'
    )) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }
}

sub _getCPUsFromProc {
    my @cpus;
    foreach my $cpu (getCPUsFromProc(@_)) {

        push @cpus, {
            ARCH  => 'm68k',
            NAME  => $cpu->{'cpu'},
            SPEED => $cpu->{'clocking'}
        };
    }

    return @cpus;
}

1;
