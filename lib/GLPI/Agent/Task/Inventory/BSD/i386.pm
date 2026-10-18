package GLPI::Agent::Task::Inventory::BSD::i386;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "bios";
use constant    other_categories => qw(cpu);

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^(i\d86|x86_64|amd64)/ if $params{remote};
    # on OpenBSD amd64 perl archname is "amd64-openbsd"
    return $Config{archname} =~ /^(i\d86|x86_64|amd64)/;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # sysctl infos
    my $bios = {
        SMODEL => getFirstLine(command => 'sysctl -n hw.model')
    };
    my $cpu = {
        NAME  => getFirstLine(command => 'sysctl -n hw.machine'),
        SPEED => (getCanonicalSpeed(split(/\s+/, $bios->{SMODEL})))[-1]
    };
    my $count = getFirstLine(command => 'sysctl -n hw.ncpu');

    # OpenBSD: without kern.allowkmem, dmidecode can't read /dev/mem
    # but system identification and cpu details are still available via sysctl
    if (OSNAME eq 'openbsd') {
        # hw.model is the cpu model, keep it before SMODEL is set to hw.product
        if ($bios->{SMODEL}) {
            $cpu->{NAME} = $bios->{SMODEL};
            my $manufacturer = getCanonicalManufacturer($bios->{SMODEL});
            if ($manufacturer && $manufacturer ne $bios->{SMODEL}) {
                $cpu->{MANUFACTURER} = $manufacturer;
            } elsif ($logger) {
                $logger->debug("unrecognized cpu manufacturer in hw.model: $bios->{SMODEL}");
            }
        }

        my %hw = map { $_ => getFirstLine(command => "sysctl -n hw.$_") }
            qw/vendor product serialno uuid cpuspeed/;
        my $cpuspeed = getCanonicalSpeed($hw{cpuspeed});
        $cpu->{SPEED} = $cpuspeed if $cpuspeed;
        $bios->{SMANUFACTURER} = $hw{vendor}   if $hw{vendor};
        $bios->{SMODEL}        = $hw{product}  if $hw{product};
        $bios->{SSN}           = $hw{serialno} if $hw{serialno};
        $inventory->setHardware({ UUID => uc($hw{uuid}) }) if $hw{uuid};
    }

    $inventory->setBios($bios);

    # don't deal with CPUs if information can be computed from dmidecode
    my $infos = getDmidecodeInfos(logger => $logger);
    return if $infos->{4};

    return if $params{no_category}->{cpu};

    # one entry by cpu package when topology is known
    if (OSNAME eq 'openbsd') {
        my @packages = _getOpenBSDCpuPackages(cpu => $cpu, logger => $logger);
        if (@packages) {
            foreach my $package (@packages) {
                $inventory->addEntry(
                    section => 'CPUS',
                    entry   => $package
                );
            }
            return;
        }
    }

    while ($count--) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }

}

# Compute CORE & THREAD by cpu package from OpenBSD kernel boot messages:
#   cpu1: smt 0, core 1, package 0, type P
sub _getOpenBSDCpuPackages {
    my (%params) = @_;

    my @lines = getAllLines(
        file => '/var/run/dmesg.boot',
        %params
    )
        or return;

    # dmesg.boot is appended at each boot, only keep messages from the last one,
    # each boot starts with the kernel version banner
    my $start = 0;
    foreach my $index (0 .. $#lines) {
        $start = $index if $lines[$index] =~ /^OpenBSD \d+\.\d+ \(/;
    }

    my %packages;
    foreach my $line (@lines[$start .. $#lines]) {
        next unless $line =~ /^cpu\d+: smt (\d+), core (\d+), package (\d+)/;
        $packages{$3}->{$2}->{$1} = 1;
    }

    my @packages;
    foreach my $package (sort { $a <=> $b } keys(%packages)) {
        my $cores = $packages{$package};
        my $threads = 1;
        foreach my $core (keys(%{$cores})) {
            my $count = scalar(keys(%{$cores->{$core}}));
            $threads = $count if $count > $threads;
        }
        push @packages, {
            %{$params{cpu}},
            CORE    => scalar(keys(%{$cores})),
            THREAD  => $threads,
        };
    }

    return @packages;
}

1;
