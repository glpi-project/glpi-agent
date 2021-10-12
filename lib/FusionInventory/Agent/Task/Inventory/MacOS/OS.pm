package FusionInventory::Agent::Task::Inventory::MacOS::OS;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::MacOS;

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

    $inventory->setOperatingSystem($os);
}

1;
