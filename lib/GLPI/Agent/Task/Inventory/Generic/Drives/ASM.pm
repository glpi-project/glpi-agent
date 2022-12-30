package GLPI::Agent::Task::Inventory::Generic::Drives::ASM;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;

sub isEnabled {
    return 0 if OSNAME eq 'MSWin32';
    return grep { $_->{CMD} =~ /^asm_pmon/ } getProcesses();
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # First get asm_pmon process
    my ($asm_pmon) = grep { $_->{CMD} =~ /^asm_pmon/ } getProcesses(logger => $logger)
        or return;

    my $user  = $asm_pmon->{USER};
    my ($asm) = $asm_pmon->{CMD} =~ /(\+ASM.*)$/
        or return;

    # Then lookup GRID_HOME in user's environment
    my $root = $user eq 'root' ? 1 : 0;
    my $grid_home = $root ? $ENV{GRID_HOME} : getFirstLine(command => "su - $user -c 'echo \$GRID_HOME'");
    if (!$grid_home && canRead("/etc/oratab")) {
        my @oratab = getAllLines(file => "/etc/oratab");
        my $asm_for_re = $asm;
        $asm_for_re =~ s/\+/\\+/;
        my ($line) = grep { /^$asm_for_re:/ } @oratab;
        ($grid_home) = $line =~ /^$asm_for_re:([^:]+):/ if $line;
    }

    # Oracle documentation:
    # see https://docs.oracle.com/cd/E11882_01/server.112/e18951/asm_util004.htm#OSTMG94549
    # But also try oracle user if grid user doesn't exist, and finally try as root
    my $cmd = ($grid_home ? "$grid_home/bin/" : "")."asmcmd lsdg";
    local $ENV{ORACLE_SID}  = $asm       if $root;
    local $ENV{ORACLE_HOME} = $grid_home if $root && $grid_home;
    $cmd = "su - $user -c \"ORACLE_SID=$asm ORACLE_HOME=$grid_home $cmd\"" unless $root;
    my $diskgroups = _getDisksGroups(
        command => $cmd,
        logger  => $logger
    );

    return unless $diskgroups;

    # Add disks groups inventory as DRIVES
    foreach my $diskgroup (@{$diskgroups}) {
        my $name = $diskgroup->{NAME}
            or next;

        # Only report mounted group
        next unless ($diskgroup->{STATE} && $diskgroup->{STATE} eq 'MOUNTED');

        $inventory->addEntry(
            section => 'DRIVES',
            entry   => {
                LABEL   => $diskgroup->{NAME},
                VOLUMN  => 'diskgroup',
                TOTAL   => $diskgroup->{TOTAL},
                FREE    => $diskgroup->{FREE}
            }
        );
    }
}

sub _getDisksGroups {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @groups = ();
    my $line_count = 0;
    foreach my $line (@lines) {
        # Cleanup line
        $line = trimWhitespace($line);

        # Logic to skip header
        $line_count ++;
        next if ($line_count == 1 && $line =~ /^State.*Name$/);

        my @infos = split(/\s+/, $line);
        next unless @infos == 13 || @infos == 14;

        # Cleanup trailing slash on NAME
        $infos[$#infos] =~ s|/+$||;

        # Fix total against TYPE field
        my $total = int($infos[$#infos-6] || 0) - int($infos[$#infos-4] || 0);
        if ($infos[1] =~ /^NORMAL|HIGH$/) {
            $total /= $infos[1] eq 'HIGH' ? 3 : 2;
        }

        push @groups, {
            NAME        => $infos[$#infos] || 'NONAME',
            STATE       => $infos[0]  || 'UNKNOWN',
            TYPE        => $infos[1]  || 'EXTERN',
            TOTAL       => int($total),
            FREE        => int($infos[$#infos-3])
        };
    }

    return \@groups;
}

1;
