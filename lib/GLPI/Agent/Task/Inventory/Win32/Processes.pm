package GLPI::Agent::Task::Inventory::Win32::Processes;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Time::HiRes qw(usleep);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Win32;

use constant    category    => "process";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $process (_getProcesses(logger => $logger)) {
        $inventory->addEntry(
            section => 'PROCESSES',
            entry   => $process
        );
    }
}

sub _getProcesses {

    my @processes;

    my $cpucount = 0;
    foreach my $proc (getWMIObjects(
        class      => 'Win32_Processor',
        properties => [ qw/NumberOfCores/ ]
    )) {
        $cpucount += int($proc->{NumberOfCores});
    }
    $cpucount = 1 unless $cpucount;

    my ($computerSystem) = getWMIObjects(
        class      => 'Win32_ComputerSystem',
        properties => [ qw/Name TotalPhysicalMemory/ ]
    );
    my $computer = uc($computerSystem->{Name});
    my $totalmem = $computerSystem->{TotalPhysicalMemory} || 0;

    my %Processes;
    foreach my $object (getWMIObjects(
        query      => 'SELECT * FROM Win32_Process WHERE ProcessId>0',
        properties => [ qw/CommandLine ProcessId CreationDate CSName Name/ ],
        method     => 'GetOwner',
        params     => [ 'User', 'Domain' ],
        User       => [ 'string', '' ],
        Domain     => [ 'string', '' ],
        selector   => 'Handle', # For winrm support
        binds      => {
            User    => 'LOGIN',
            Domain  => 'DOMAIN'
        }
    )) {
        # Always skip System Idle Process entry
        next unless $object->{ProcessId};

        my $process = {
            PID => $object->{ProcessId},
            CMD => $object->{CommandLine} // $object->{Name},
        };

        my $user = $object->{LOGIN} // "";
        $user .= '@' . $object->{DOMAIN} unless empty($object->{DOMAIN}) ||
            $object->{DOMAIN} eq "NT AUTHORITY" ||
            ($computer && uc($object->{DOMAIN}) eq $computer);
        $process->{USER} = empty($user) ? $object->{Name} : $user;

        unless (empty($object->{CreationDate})) {
            my ($year, $month, $day, $hour, $minute, $second) =
                $object->{CreationDate} =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\.\d+/;
            $process->{STARTED} = sprintf(
                "%04d-%02d-%02d %02d:%02d:%02d",
                $year, $month, $day, $hour, $minute, $second
            );
        }

        # Filter out on missing required field
        next if empty($process->{CMD}) || empty($process->{USER});

        # Index process for performance data analysis
        $Processes{$process->{PID}} = $process;

        push @processes, $process;
    }

    # Prepare processes stats to query
    my @perfs = (
        class      => 'Win32_PerfRawData_PerfProc_Process',
        properties => [ qw/
            IDProcess Timestamp_Sys100NS PercentProcessorTime
            VirtualBytes WorkingSet
        / ]
    );

    # Forget our recent load to capture more real workload
    usleep(100000);

    # Get first performance datas
    my @firststats = getWMIObjects(@perfs);

    # Wait a little to leave other processes update performance datas
    usleep(500000);

    # Get last performance datas
    my @laststats = getWMIObjects(@perfs);

    my %first = map { $_->{IDProcess} => $_ } @firststats;
    foreach my $perf (@laststats) {
        # We can skip pid 0 which is not relevant
        my $pid = $perf->{IDProcess}
            or next;
        # Skip unknown process as may be new process
        next unless $Processes{$pid} && $first{$pid};
        # Compute stat
        my $period = $perf->{Timestamp_Sys100NS} - $first{$pid}->{Timestamp_Sys100NS};
        next unless $period > 0;
        my $proctime = $perf->{PercentProcessorTime} - $first{$pid}->{PercentProcessorTime};
        next unless $proctime >= 0;
        my $usage = 100*$proctime/$period/$cpucount;
        $Processes{$pid}->{CPUUSAGE} = sprintf("%.2f", $usage);
        $Processes{$pid}->{VIRTUALMEMORY} = getCanonicalSize($perf->{VirtualBytes}." bytes", 1024)
            if $perf->{VirtualBytes};
        $Processes{$pid}->{MEM} = sprintf("%.02f", 100*$perf->{WorkingSetSize}/$totalmem)
            if $perf->{WorkingSetSize} && $totalmem;
    }

    return @processes;
}

1;
