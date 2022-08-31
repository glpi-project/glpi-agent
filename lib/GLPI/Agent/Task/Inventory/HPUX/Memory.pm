package GLPI::Agent::Task::Inventory::HPUX::Memory;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::HPUX;
use English qw(-no_match_vars);

use constant    category    => "memory";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @memories;

    # http://forge.fusioninventory.org/issues/754
    if (canRun('/opt/propplus/bin/cprop') && !isHPVMGuest()) {
        @memories = _parseCprop(
            command => '/opt/propplus/bin/cprop -summary -c Memory',
            logger  => $logger
        );
    } else {
        my $arch = Uname("-m");

        if ($arch =~ /ia64/ ) {
            # enable infolog
            system("echo 'sc product  IPF_MEMORY;info' | /usr/sbin/cstm");
            @memories = _parseCstm64(
                command => "echo 'sc product IPF_MEMORY;il' | /usr/sbin/cstm",
                logger  => $logger
            );
        } else {
            @memories = _parseCstm(
                command => "echo 'sc product mem;il'| /usr/sbin/cstm",
                logger  => $logger
            );
        }
    }

    my $memorySize;
    my $swapSize = getFirstMatch(
        command => 'swapinfo -dt',
        logger  => $logger,
        pattern => qr/^total\s+(\d+)/
    );

    foreach my $memory (@memories) {
        $inventory->addEntry(
            section => 'MEMORIES',
            entry   => $memory
        );
        $memorySize += $memory->{CAPACITY};
    }

    $inventory->setHardware({
        SWAP   => int($swapSize / 1024),
        MEMORY => $memorySize
    });
}

sub _parseCprop {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @memories;
    my $instance;

    foreach my $line (@lines) {
        if ($line =~ /\[Instance\]: \d+/) {
            # new block
            $instance = {};
            next;
        }

        if ($line =~ /^ \s+ \[ ([^\]]+) \]: \s (\S+.*)/x) {
            $instance->{$1} = $2;
            next;
        }

        if ($line =~ /^\*+/) {
            next unless keys %$instance;
            next unless $instance->{Size};
            push @memories, {
                CAPACITY     => getCanonicalSize($instance->{Size}, 1024),
                DESCRIPTION  => $instance->{'Part Number'},
                SERIALNUMBER => $instance->{'Serial Number'},
                TYPE         => $instance->{'Module Type'},
            };
        }
    }

    return @memories;
}

sub _parseCstm {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @memories;

    my %capacities;
    my $capacity = 0;
    my $description;
    my $numslot = 1;
    my $subnumslot;
    my $serialnumber = 'No Serial Number available!';
    my $type;
    my $ok = 0;

    foreach my $line (@lines) {

        if ($line =~ /FRU\sSource\s+=\s+\S+\s+\(memory/ ) {
            $ok = 0;
        }
        if ($line =~ /Source\s+Detail\s+=\s4/ ) {
            $ok = 1;
        }
        if ($line =~ /\s+(\d+)\s+(\d+)/ ) {
            $capacities{$1} = $2;
        }
        if ($line =~ /Extender\s+Location\s+=\s+(\S+)/ ) {
            $subnumslot = $1;
        };
        if ($line =~ /DIMMS\s+Rank\s+=\s+(\S+)/ ) {
            $numslot = sprintf("%02x",$1);
        }

        if ($line =~ /FRU\s+Name\.*:\s+(\S+)/ ) {
            if ($line =~ /(\S+)_(\S+)/ ) {
                $type = $1;
                $capacity = $2;
            } elsif ($line =~ /(\wIMM)(\S+)/ ) {
                $ok = 1;
                $type = $1;
                $numslot = $2;
            }
        }
        if ($line =~ /Part\s+Number\.*:\s*(\S+)\s+/ ) {
            $description = $1;
        }
        if ($line =~ /Serial\s+Number\.*:\s*(\S+)\s+/ ) {
            $serialnumber = $1;
            if ( $ok eq 1 ) {
                if ( $capacity eq 0 ) {
                    $capacity = $capacities{$numslot};
                }
                push @memories, {
                    CAPACITY     => $capacity,
                    DESCRIPTION  => "Part Number $description",
                    CAPTION      => "Ext $subnumslot Slot $numslot",
                    TYPE         => $type,
                    NUMSLOTS     => '1',
                    SERIALNUMBER => $serialnumber,
                };
                $ok = 0;
                $capacity = 0;
            } # $ok eq 1
        } # /Serial\s+Number\.*:\s*(\S+)\s+/

    }

    return @memories;
}

sub _parseCstm64 {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @memories;

    foreach my $line (@lines) {

        # this pattern assumes memory slots are correctly
        # balanced (slot A and slot B are occuped)
        next unless $line =~ /
            (\w+IMM)\s+(\w+)\s+(\d+) # first column
            \s+
            (\w+IMM)\s+(\w+)\s+(\d+) # second column
        /x;

        push @memories, {
            CAPACITY     => $3,
            DESCRIPTION  => $1,
            CAPTION      => $1 . ' ' . $2,
            TYPE         => $1,
            NUMSLOTS     => $2,
        }, {
            CAPACITY     => $6,
            DESCRIPTION  => $4,
            CAPTION      => $4 . ' ' . $5,
            TYPE         => $4,
            NUMSLOTS     => $5,
        };
    }

    return @memories;
}

1;
