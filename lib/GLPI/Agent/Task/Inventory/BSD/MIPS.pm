package GLPI::Agent::Task::Inventory::BSD::MIPS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;

use constant    category    => "bios";
use constant    other_categories => qw(cpu);

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^mips/ if $params{remote};
    return $Config{archname} =~ /^mips/;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $bios = {
        SMANUFACTURER => 'SGI',
    };

    # sysctl infos

    # example on NetBSD: SGI-IP22
    # example on OpenBSD: SGI-O2 (IP32)
    $bios->{SMODEL} = getFirstLine(command => 'sysctl -n hw.model');

    my $count = getFirstLine(command => 'sysctl -n hw.ncpu');

    # dmesg infos

    # I) Indy
    # NetBSD:
    # mainbus0 (root): SGI-IP22 [SGI, 6906e152], 1 processor
    # cpu0 at mainbus0: MIPS R4400 CPU (0x450) Rev. 5.0 with MIPS R4010 FPC Rev. 0.0
    # int0 at mainbus0 addr 0x1fbd9880: bus 75MHz, CPU 150MHz
    #
    # II) O2
    # NetBSD:
    # mainbus0 (root): SGI-IP32 [SGI, 8], 1 processor
    # cpu0 at mainbus0: MIPS R5000 CPU (0x2321) Rev. 2.1 with built-in FPU Rev. 1.0
    # OpenBSD:
    # mainbus0 (root)
    # cpu0 at mainbus0: MIPS R5000 CPU rev 2.1 180 MHz with R5000 based FPC rev 1.0
    # cpu0: cache L1-I 32KB D 32KB 2 way, L2 512KB direct

    my $cpu;
    foreach my $line (getAllLines(command => 'dmesg')) {
        if ($line =~ /$bios->{SMODEL}\s*\[\S*\s*(\S*)\]/) { $bios->{SSN} = $1; }
        if ($line =~ /cpu0 at mainbus0:\s*(.*)$/)         { $cpu->{NAME} = $1; }
        if ($line =~ /CPU\s*.*\D(\d+)\s*MHz/)             { $cpu->{SPEED} = $1;  }
    }

    $inventory->setBios($bios);

    return if $params{no_category}->{cpu};

    while ($count--) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }
}

1;
