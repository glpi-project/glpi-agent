package FusionInventory::Agent::Task::Inventory::Linux::PowerPC::CPU;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools::Linux;

use constant    category    => "cpu";

sub isEnabled {
    return has_file('/proc/cpuinfo');
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

        my $speed;
        if (
            $cpu->{clock} &&
            $cpu->{clock} =~ /(\d+)/
        ) {
            $speed = $1;
        }

        my $manufacturer;
        if ($cpu->{machine} &&
            $cpu->{machine} =~ /IBM/
        ) {
            $manufacturer = 'IBM';
        }

        push @cpus, {
            ARCH         => 'PowerPC',
            NAME         => $cpu->{cpu},
            MANUFACTURER => $manufacturer,
            SPEED        => $speed
        };
    }

    return @cpus;
}

1;
