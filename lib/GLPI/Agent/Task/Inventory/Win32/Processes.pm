package GLPI::Agent::Task::Inventory::Win32::Processes;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

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

    my ($computerSystem) = getWMIObjects(
        class      => 'Win32_ComputerSystem',
        properties => [ qw/
            Name TotalPhysicalMemory
        / ]
    );
    my $computer = uc($computerSystem->{Name});
    my $totalmem = $computerSystem->{TotalPhysicalMemory} // 0;

    foreach my $object (getWMIObjects(
        class      => 'Win32_Process',
        properties => [ qw/
            CommandLine ProcessId VirtualSize WorkingSetSize
            CreationDate CSName Name
        / ],
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
        # Skip System Idle Process entry
        next if empty($object->{CommandLine}) && $object->{Name} =~ /System Idle Process/i;

        my $process = {
            PID           => $object->{ProcessId},
            VIRTUALMEMORY => getCanonicalSize(($object->{VirtualSize}//0)." bytes", 1024),
            CMD           => $object->{CommandLine} // $object->{Name},
        };

        my $user = $object->{LOGIN};
        $user .= '@' . $object->{DOMAIN} unless empty($object->{DOMAIN}) ||
            $object->{DOMAIN} eq "NT AUTHORITY" ||
            ($computer && uc($object->{DOMAIN}) eq $computer);
        $process->{USER} = empty($user) ? $object->{Name} : $user;

        my ($year, $month, $day, $hour, $minute, $second) =
            $object->{CreationDate} =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\.\d+/;
        $process->{STARTED} = sprintf(
            "%04d-%02d-%02d %02d:%02d:%02d",
            $year, $month, $day, $hour, $minute, $second
        );

        $process->{MEM} = sprintf("%.02f", ($object->{WorkingSetSize}//0)/$totalmem*100)
            if $totalmem;

        # Filter out on missing required field
        next if empty($process->{CMD}) || empty($process->{USER}) || empty($process->{PID});

        push @processes, $process;
    }

    return @processes;
}

1;
