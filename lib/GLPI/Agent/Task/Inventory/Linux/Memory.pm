package GLPI::Agent::Task::Inventory::Linux::Memory;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "memory";

sub isEnabled {
    return canRead('/proc/meminfo');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my @lines = getAllLines(
        file    => '/proc/meminfo',
        logger  => $params{logger}
    );

    my $memoryLine = first { /^MemTotal:\s*(\d+)/ } @lines;
    my $swapLine = first { /^SwapTotal:\s*(\d+)/ } @lines;

    my $hw;
    $hw->{MEMORY} = int($1/1024) if $memoryLine && $memoryLine =~ /(\d+)/;
    $hw->{SWAP}   = int($1/1024) if $swapLine   && $swapLine   =~ /(\d+)/;

    $inventory->setHardware($hw);
}

1;
