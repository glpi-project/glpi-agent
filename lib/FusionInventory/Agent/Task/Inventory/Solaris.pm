package FusionInventory::Agent::Task::Inventory::Solaris;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Solaris;

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME eq 'solaris';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Operating system informations
    my $info          = getReleaseInfo();
    my $kernelArch    = getFirstLine(command => 'arch -k');
    my $kernelVersion = getFirstLine(command => 'uname -v');
    my $proct         = getFirstLine(command => 'uname -p');
    my $platform      = getFirstLine(command => 'uname -i');
    my $hostid        = getFirstLine(command => 'hostid');
    my $description   = "$platform($kernelArch)/$proct HostID=$hostid";

    $inventory->setHardware({
        OSNAME      => "Solaris",
        OSVERSION   => $info->{version},
        OSCOMMENTS  => $info->{subversion},
        DESCRIPTION => $description
    });

    $inventory->setOperatingSystem({
        NAME           => "Solaris",
        HOSTID         => $hostid,
        FULL_NAME      => $info->{fullname},
        VERSION        => $info->{version},
        SERVICE_PACK   => $info->{subversion},
        KERNEL_VERSION => $kernelVersion
    });
}

1;
