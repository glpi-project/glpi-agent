package GLPI::Agent::Task::Inventory::Linux::Memory;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "memory";

sub isEnabled {
    return has_file('/proc/meminfo');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $handle = getFileHandle(file => '/proc/meminfo', logger => $logger);
    return unless $handle;

    my $memorySize;
    my $swapSize;

    while (my $line = <$handle>) {
        $memorySize = $1 if $line =~ /^MemTotal:\s*(\S+)/;
        $swapSize = $1 if $line =~ /^SwapTotal:\s*(\S+)/;
    }
    close $handle;

    $inventory->setHardware({
        MEMORY => int($memorySize/ 1024),
        SWAP   => int($swapSize / 1024),
    });
}

1;
