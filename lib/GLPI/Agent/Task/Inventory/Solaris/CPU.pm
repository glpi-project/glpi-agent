package GLPI::Agent::Task::Inventory::Solaris::CPU;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Solaris;

use constant    category    => "cpu";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $cpu (_getCPUs()) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }

}

sub _getCPUs {
    my (%params) = @_;

    # get virtual CPUs from psrinfo -v
    my @all_virtual_cpus = _getVirtualCPUs(logger => $params{logger});

    # get physical CPUs from psrinfo -vp
    my @all_physical_cpus = _getPhysicalCPUs(logger => $params{logger});

    # count the different speed values
    # undef is temporarily mapped to 0, to avoid warnings
    my @physical_speeds =
        map { $_ ? $_ : undef }
        sort { $a <=> $b }
        uniq
        map { $_->{speed} || 0 }
        @all_physical_cpus;

    my @virtual_speeds =
        map { $_ ? $_ : undef }
        sort { $a <=> $b }
        uniq
        map { $_->{speed} || 0 }
        @all_virtual_cpus;

    my @cpus;

    # process CPUs by groups, according to their speed
    while (@physical_speeds) {
        my $physical_speed = shift @physical_speeds;
        my $virtual_speed  = shift @virtual_speeds;

        my @physical_cpus = $physical_speed ?
            grep { $_->{speed} eq $physical_speed } @all_physical_cpus:
            grep { ! defined $_->{speed}          } @all_physical_cpus;
        my @virtual_cpus  = $virtual_speed ?
            grep { $_->{speed} eq $virtual_speed } @all_virtual_cpus:
            grep { ! defined $_->{speed}         } @all_virtual_cpus;

        my $speed = $physical_cpus[0]->{speed} || $virtual_cpus[0]->{speed};
        my $type  = $physical_cpus[0]->{type}  || $virtual_cpus[0]->{type};
        my $manufacturer =
            $type =~ /SPARC/      ? 'SPARC' :
            $type =~ /Xeon|Intel/ ? 'Intel' :
            $type =~ /AMD/        ? 'AMD'   :
                                    undef   ;
        my $cpus  = scalar @physical_cpus;

        my ($cores, $threads) =
            $type eq 'UltraSPARC-IV'  ? (2,     1) : # US-IV & US-IV+
            $type eq 'UltraSPARC-T1'  ? (undef, 4) : # Niagara
            $type eq 'UltraSPARC-T2'  ? (undef, 8) : # Niagara-II
            $type eq 'UltraSPARC-T2+' ? (undef, 8) : # Victoria Falls
            $type eq 'SPARC-T3'       ? (undef, 8) : # Rainbow Falls
            $type eq 'SPARC-T4'       ? (8    , 8) : # Yosemite Falls
            $type eq 'SPARC-T5'       ? (16   , 8) :
            $type eq 'SPARC-M7'       ? (32   , 8) :
            $type eq 'SPARC-M8'       ? (32   , 8) :
            $type eq 'SPARC64-VI'     ? (2,     2) : # Olympus-C SPARC64-VI
            $type eq 'SPARC64-VII'    ? (4,     2) : # Jupiter SPARC64-VII
            $type eq 'SPARC64-VII+'   ? (4,     2) : # Jupiter+ SPARC64-VII+
            $type eq 'SPARC64-VII++'  ? (4,     2) : # Jupiter++ SPARC64-VII++
            $type eq 'SPARC64-VIII'   ? (8,     2) : # Venus SPARC64-VIII
                                        (1,     1) ;

        if ($type =~ /MB86907/) {
            $type = "TurboSPARC-II $type";
        } elsif ($type =~ /MB86904|390S10/) {
            $type = ($speed > 70) ? "microSPARC-II $type" : "microSPARC $type";
        } elsif ($type =~ /,RT62[56]/) {
            $type = "hyperSPARC $type";
        }

        # deduce core numbers from number of virtual cpus if needed
        if (!$cores) {
            # cores may be < 1 in case of virtualisation
            $cores = (scalar @virtual_cpus) / $threads / $cpus;
        }

        # Type may contain core number information
        if ($type =~ /^(.*) (\d+)-Core/) {
            $type = $1;
            $cores = int($2);
        }

        for my $i (1 .. $cpus) {
            push @cpus,
                {
                    MANUFACTURER => $manufacturer,
                    NAME         => $type,
                    SPEED        => $speed,
                    CORE         => $cores,
                    THREAD       => $threads
                };
        }
    }

    return @cpus;
}

sub _getVirtualCPUs {
    my %params = (
        command => '/usr/sbin/psrinfo -v',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @cpus;
    foreach my $line (@lines) {
        if ($line =~ /The (\S+) processor operates at (\d+) MHz/) {
            push @cpus, {
                type  => $1,
                speed => $2,
            };
        }
    }

    return @cpus;
}

sub _getPhysicalCPUs {
    my %params = (
        command => '/usr/sbin/psrinfo -vp',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @cpus;
    foreach my $line (@lines) {
        $line = getSanitizedString($line);

        if ($line =~ /^The physical processor has (\d+) virtual/) {
            push @cpus, {
                count => $1
            };
            next;
        }

        if ($line =~ /^The physical processor has (\d+) cores and (\d+) virtual/) {
            push @cpus, {
                count => $2
            };
            next;
        }

        if ($line =~ /^The (\S+) physical processor has (\d+) virtual/) {
            push @cpus, {
                type  => $1,
                count => $2
            };
            next;
        }

        if ($line =~ /(\S+) \(.* clock (\d+) MHz\)/) {
            my $cpu = $cpus[-1];
            $cpu->{type} = $1;
            $cpu->{speed} = $2;
            next;
        }

        if ($line =~ /Intel\(r\) Xeon\(r\) CPU +(\S+)/) {
            my $cpu = $cpus[-1];
            $cpu->{type} = "Xeon $1";
        }

        if ($line =~ /(\S.+) Processor/) {
            my $cpu = $cpus[-1];
            $cpu->{type} = $1;
        }
    }

    return @cpus;
}

1;
