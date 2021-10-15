package GLPI::Agent::Task::Inventory::AIX::Memory;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::AIX;

use constant    category    => "memory";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $memory (_getMemories()) {
        $inventory->addEntry(
            section => 'MEMORIES',
            entry   => $memory
        );
    }

    #Memory informations
    #lsdev -Cc memory -F 'name' -t totmem
    #lsattr -EOlmem0
    my $memorySize = 0;
    my @lsdev = getAllLines(
        command => 'lsdev -Cc memory -F "name" -t totmem',
        logger  => $logger
    );
    foreach (@lsdev){
        my @lsattr = getAllLines(
            command => "lsattr -EOl $_",
            logger  => $logger
        );
        foreach (@lsattr) {
            if (! /^#/){
                # See: http://forge.fusioninventory.org/issues/399
                # TODO: the regex should be improved here
                /^(.+):(\d+)/;
                $memorySize += $2;
            }
        }
    }

    #Paging Space
    my $swapSize;
    my @grep = getAllLines(command => 'lsps -s', logger => $logger);
    foreach (@grep){
        if ( ! /^Total/){
            /^\s*(\d+)\w*\s+\d+.+/;
            $swapSize = $1;
        }
    }

    $inventory->setHardware({
        MEMORY => $memorySize,
        SWAP   => $swapSize
    });

}

sub _getMemories {
    my @infos = getLsvpdInfos(@_);
    my @memories;
    my $numslots = 0;

    foreach my $info (@infos) {
        next unless $info->{DS} eq 'Memory DIMM';

        push @memories, {
            DESCRIPTION => $info->{DS},
            CAPACITY    => $info->{SZ},
            CAPTION     => 'Slot ' . $info->{YL},
            SERIALNUMBER=> $info->{SN},
            NUMSLOTS    => $numslots++
        };
    }

    return @memories;
}

1;
