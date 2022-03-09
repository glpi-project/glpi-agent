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
    if (has_file("/var/db/.AppleSetupDone")) {
        my $installdate = _getInstallDate(
            command => "stat -f \%m /var/db/.AppleSetupDone",
            logger  => $logger
        );
        $os->{INSTALL_DATE} = $installdate
            if $installdate;
    }

    $inventory->setOperatingSystem($os);
}

sub _getInstallDate {
    my (%params) = @_;

    my $date = getFirstLine(%params)
        or return;

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
