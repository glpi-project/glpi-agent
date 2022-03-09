package GLPI::Agent::Task::Inventory::MacOS::OS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::MacOS;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $kernelRelease = Uname("-r");
    my $kernelArch    = Uname("-m");

    my $boottime = getBootTime();

    my $os = {
        NAME           => "MacOSX",
        KERNEL_VERSION => $kernelRelease,
        ARCH           => $kernelArch,
        BOOT_TIME      => getFormatedLocalTime($boottime)
    };

    my $infos = getSystemProfilerInfos(
        logger  => $logger,
        type    => 'SPSoftwareDataType',
    );
    my $SystemVersion = $infos->{'Software'}->{'System Software Overview'}->{'System Version'};
    if ($SystemVersion =~ /^(.*?)\s+(\d+.*)/) {
        $os->{FULL_NAME} = $1;
        $os->{VERSION}   = $2;
    }

    # Parse /var/log/install.log and use the last kern.boottime before install is finished as install date
    if (has_file("/var/log/install.log")) {
        my $installdate = _getInstallDate(
            file   => "/var/log/install.log",
            logger => $logger
        );
        $os->{INSTALL_DATE} = $installdate
            if $installdate;
    }

    $inventory->setOperatingSystem($os);
}

sub _getInstallDate {
    my (%params) = @_;

    my ($date, $ts);
    foreach my $line (getAllLines(%params)) {
        if ($line =~ /(\d+):(\d+):(\d+).*kern\.boottime: \{ sec = (\d+),/) {
            $date = int($4);
            $ts = $1 * 3600 + $2 * 60 + $3;
        } elsif ($line =~ /(\d+):(\d+):(\d+).*------- Install Complete -------/) {
            my $this_ts = $1 * 3600 + $2 * 60 + $3;
            if ($this_ts > $ts) {
                $date += $this_ts - $ts;
            } else {
                $date += 86400 - $ts + $this_ts;
            }
        }
    }

    return unless $date;

    if (DateTime->require()) {
        eval {
            my $dt = DateTime->from_epoch( epoch => $date );
            $date = $dt->datetime(' ');
        }
    } else {
        $date = getFormatedLocalTime($date);
    }

    return $date;
}

1;
