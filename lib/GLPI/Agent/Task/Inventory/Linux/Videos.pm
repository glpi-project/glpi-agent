package GLPI::Agent::Task::Inventory::Linux::Videos;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;

use constant    category    => "video";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $videos = $inventory->getSection('VIDEOS') || [];
    # Assume videos was detected via pci scan
    return if @{$videos};

    $logger->debug("retrieving display information:");

    my $ddcprobeData;
    if (canRun('ddcprobe')) {
        $ddcprobeData = _getDdcprobeData(
            command => 'ddcprobe',
            logger  => $logger
        );
         $logger->debug_result(
             action => 'running ddcprobe command',
             data   => $ddcprobeData
         );
    } else {
        $logger->debug_result(
             action => 'running ddcprobe command',
             status => 'command not available'
        );
    }

    my $xorgData;

    my $xorgPid;
    foreach my $process (getProcesses(logger  => $logger)) {
        next unless $process->{CMD} =~ m{
            ^
            (?:
                /usr/bin
                |
                /usr/X11R6/bin
                |
                /etc/X11
                |
                /usr/libexec
            )
            /X
        }x;
        $xorgPid = $process->{PID};
        last;
    }

    if ($xorgPid) {
        my $fd = 0;
        my %read;
        while (canRead("/proc/$xorgPid/fd/$fd")) {
            my $link = ReadLink("/proc/$xorgPid/fd/$fd");
            $fd++;
            next unless $link =~ /\.log$/;
            next if $read{$link};
            if (has_file($link)) {
                $xorgData = _parseXorgFd(file => $link);
                $logger->debug_result(
                     action => "reading $link Xorg log file",
                     data   => $xorgData
                );
                last if $xorgData;
                $read{$link} = 1;
            } else {
                $logger->debug_result(
                     action => "reading $link Xorg log file",
                     status => "non-readable link $link"
                );
            }
        }
    } else {
        $logger->debug_result(
             action => 'reading Xorg log file',
             status => 'unable to get Xorg PID'
        );
    }

    return unless $xorgData || $ddcprobeData;

    my $video = {
        CHIPSET    => $xorgData->{product}    || $ddcprobeData->{product},
        MEMORY     => $xorgData->{memory}     || $ddcprobeData->{memory},
        NAME       => $xorgData->{name}       || $ddcprobeData->{oem},
        RESOLUTION => $xorgData->{resolution} || $ddcprobeData->{dtiming},
        PCISLOT    => $xorgData->{pcislot},
        PCIID      => $xorgData->{pciid},
    };

    if ($video->{MEMORY} && $video->{MEMORY} =~ s/kb$//i) {
        $video->{MEMORY} = int($video->{MEMORY} / 1024);
    }
    if ($video->{RESOLUTION}) {
        $video->{RESOLUTION} =~ s/@.*//;
    }

    $inventory->addEntry(
        section => 'VIDEOS',
        entry   => $video
    );
}

sub _getDdcprobeData {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $data;
    foreach my $line (@lines) {
        $line =~ s/[[:cntrl:]]//g;
        $line =~ s/[^[:ascii:]]//g;
        $data->{$1} = $2 if $line =~ /^(\S+):\s+(.*)/;
    }

    return $data;
}

sub _parseXorgFd {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $data;
    foreach my $line (@lines) {
        if ($line =~ /Modeline\s"(\S+?)"/) {
            $data->{resolution} = $1 if !$data->{resolution};
        } elsif ($line =~ /Integrated Graphics Chipset:\s+(.*)/) {
            # Intel
            $data->{name} = $1;
        } elsif ($line =~ /Virtual screen size determined to be (\d+)\s*x\s*(\d+)/) {
            # Nvidia
            $data->{resolution} = "$1x$2";
        } elsif ($line =~ /NVIDIA GPU\s*(.*?)\s*at/) {
            $data->{name} = $1;
        } elsif ($line =~ /VESA VBE OEM:\s*(.*)/) {
            $data->{name} = $1;
        } elsif ($line =~ /VESA VBE OEM Product:\s*(.*)/) {
            $data->{product} = $1;
        } elsif ($line =~ /(?:VESA VBE Total Mem| Memory): (\d+)\s*(\w+)/i) {
            $data->{memory} = $1 . substr($2, 0, 2);
        } elsif ($line =~ /RADEON\(0\): Chipset: "(.*?)"/i) {
            # ATI /Radeon
            $data->{name} = $1;
        } elsif ($line =~ /Virtual size is (\S+)/i) {
            # VESA / XFree86
            $data->{resolution} = $1;
        } elsif ($line =~ /
            PCI: \* \( (?:\d+:)? (\d+) : (\d+) : (\d+) \) \s
            (\w{4}:\w{4}:\w{4}:\w{4})?
        /x) {
            $data->{pcislot} = sprintf("%02d:%02d.%d", $1, $2, $3);
            $data->{pciid}   = $4 if $4;
        } elsif ($line =~ /NOUVEAU\(0\): Chipset: "(.*)"/) {
            # Nouveau
            $data->{product} = $1;
        }
    }

    return $data;
}

1;
