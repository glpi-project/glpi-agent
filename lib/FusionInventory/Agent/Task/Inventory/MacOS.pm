package FusionInventory::Agent::Task::Inventory::MacOS;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::MacOS;

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME eq 'darwin';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # basic operating system informations
    my $kernelVersion = getFirstLine(command => 'uname -v');
    my $kernelRelease = getFirstLine(command => 'uname -r');
    my $kernelArch    = getFirstLine(command => 'uname -m');

    my ($name, $version);
    my $infos = getSystemProfilerInfos(type => 'SPSoftwareDataType', logger => $logger);
    my $SystemVersion =
        $infos->{'Software'}->{'System Software Overview'}->{'System Version'};
    if ($SystemVersion =~ /^(.*?)\s+(\d+.*)/) {
        $name = $1;
        $version = $2;
    } else {
        $name = "Mac OS X";
    }

    my $boottime = getBootTime();

    $inventory->setHardware({
        OSNAME     => $name,
        OSVERSION  => $version,
        OSCOMMENTS => $kernelVersion,
    });

    $inventory->setOperatingSystem({
        NAME           => "MacOSX",
        FULL_NAME      => $name,
        VERSION        => $version,
        KERNEL_VERSION => $kernelRelease,
        ARCH           => $kernelArch,
        BOOT_TIME      => getFormatedLocalTime($boottime)
    });
}

1;
