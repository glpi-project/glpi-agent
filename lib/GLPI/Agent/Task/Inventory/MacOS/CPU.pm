package GLPI::Agent::Task::Inventory::MacOS::CPU;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::MacOS;

use constant    category    => "cpu";

sub isEnabled {
    return canRun('/usr/sbin/system_profiler');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $cpu (_getCpus(logger => $logger)) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }
}

sub _getCpus {
    my (%params) = @_;

    # system profiler informations
    my $infos = getSystemProfilerInfos(
        type   => 'SPHardwareDataType',
        logger => $params{logger},
        file   => $params{file}
    );

    my $sysprofile_info = $infos->{'Hardware'}->{'Hardware Overview'};

    # more informations from sysctl
    my @lines = getAllLines(
        logger  => $params{logger},
        command => 'sysctl -a machdep.cpu',
        file    => $params{sysctl}
    );
    return unless @lines;

    my $sysctl_info;
    foreach my $line (@lines) {
        next unless $line =~ /([^:]+) : \s (.+)/x;
        $sysctl_info->{$1} = $2;
    }

    my $type  = $sysctl_info->{'machdep.cpu.brand_string'} ||
                $sysprofile_info->{'Processor Name'} ||
                $sysprofile_info->{'CPU Type'};
    my $procs = $sysprofile_info->{'Number Of Processors'} ||
                $sysprofile_info->{'Number Of CPUs'}       ||
                1;
    my $speed = $sysprofile_info->{'Processor Speed'} ||
                $sysprofile_info->{'CPU Speed'}       || "";

    my $stepping = $sysctl_info->{'machdep.cpu.stepping'};
    my $family   = $sysctl_info->{'machdep.cpu.family'};
    my $model    = $sysctl_info->{'machdep.cpu.model'};
    my $threads  = $sysctl_info->{'machdep.cpu.thread_count'};

    # French Mac returns 2,60 Ghz instead of 2.60 Ghz :D
    $speed =~ s/,/./;
    if ($speed =~ /GHz$/i) {
        $speed =~ s/GHz//i;
        $speed = $speed * 1000;
    } elsif ($speed =~ /MHz$/i){
        $speed =~ s/MHz//i;
    }
    $speed =~ s/\s//g;

    my $cores = $sysprofile_info->{'Total Number Of Cores'} ?
        $sysprofile_info->{'Total Number Of Cores'} / $procs :
        $sysctl_info->{'machdep.cpu.core_count'};

    my $manufacturer =
        $type =~ /Intel/i ? "Intel" :
        $type =~ /AMD/i   ? "AMD"   :
        $type =~ /Apple/i ? "Apple" :
                            undef   ;

    my @cpus;
    my $cpu = {
        CORE         => $cores,
        MANUFACTURER => $manufacturer,
        NAME         => trimWhitespace($type),
        THREAD       => $threads,
    };

    # Intel/Amd
    $cpu->{FAMILYNUMBER} = $family   if defined($family);
    $cpu->{MODEL}        = $model    if defined($model);
    $cpu->{STEPPING}     = $stepping if defined($stepping);
    $cpu->{SPEED}        = $speed    if $speed;

    for (my $i=0; $i < $procs; $i++) {
        push @cpus, $cpu;
    }

    return @cpus;

}



1;
