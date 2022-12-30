package GLPI::Agent::Task::Inventory::Linux::SPARC::CPU;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Linux;

use constant    category    => "cpu";

sub isEnabled {
    return canRead('/proc/cpuinfo');
};

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
    my $cpu = (getCPUsFromProc(@_))[0];

    return unless $cpu && $cpu->{'ncpus probed'};

    my @cpus;
    foreach (1 .. $cpu->{'ncpus probed'}) {
        push @cpus, {
            ARCH => 'sparc',
            NAME => $cpu->{cpu},
        };
    }

    return @cpus;
}



1;
