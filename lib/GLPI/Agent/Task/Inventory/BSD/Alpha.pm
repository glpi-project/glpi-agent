package GLPI::Agent::Task::Inventory::BSD::Alpha;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;

use constant    category    => "bios";
use constant    other_categories => qw(cpu);

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^alpha/ if $params{remote};
    return $Config{archname} =~ /^alpha/;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $bios = {
        SMANUFACTURER => 'DEC',
    };

    # sysctl infos

    # example on *BSD: AlphaStation 255 4/232
    $bios->{SMODEL} = getFirstLine(command => 'sysctl -n hw.model');

    my $count = getFirstLine(command => 'sysctl -n hw.ncpu');

    # dmesg infos

    # NetBSD:
    # AlphaStation 255 4/232, 232MHz, s/n
    # cpu0 at mainbus0: ID 0 (primary), 21064A-2
    # OpenBSD:
    # AlphaStation 255 4/232, 232MHz
    # cpu0 at mainbus0: ID 0 (primary), 21064A-2 (pass 1.1)
    # FreeBSD:
    # AlphaStation 255 4/232, 232MHz
    # CPU: EV45 (21064A) major=6 minor=2

    my $cpu;
    foreach my $line (getAllLines(command => 'dmesg')) {
        if ($line =~ /$bios->{SMODEL},\s*(\S+)\s*MHz/) { $cpu->{SPEED} = $1; }
        if ($line =~ /^cpu[^:]*:\s*(.*)$/i)            { $cpu->{NAME} = $1;  }
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
