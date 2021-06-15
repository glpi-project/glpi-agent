package FusionInventory::Agent::Task::Inventory::Linux::ARM::CPU;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Linux;

use constant    category    => "cpu";

sub isEnabled {
    return -r '/proc/cpuinfo';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $cpu (_getCPUsFromProc(
        logger => $logger, file => '/proc/cpuinfo')
    ) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }
}

sub _getCPUsFromProc {
    my @cpus;

    # https://github.com/joyent/libuv/issues/812
    foreach my $cpu (getCPUsFromProc(@_)) {
        push @cpus, {
            ARCH  => 'ARM',
            NAME  => $cpu->{'model name'} || $cpu->{processor}
        };
    }

    return @cpus;
}

1;
