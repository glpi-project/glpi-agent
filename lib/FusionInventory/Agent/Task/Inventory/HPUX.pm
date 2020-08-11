package FusionInventory::Agent::Task::Inventory::HPUX;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Generic"];

sub isEnabled  {
    return OSNAME eq 'hpux';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Operating system informations
    my $kernelVersion = getFirstLine(command => 'uname -v');
    my $kernelRelease = getFirstLine(command => 'uname -r');
    my $OSLicense     = getFirstLine(command => 'uname -l');

    $inventory->setHardware({
        OSNAME     => 'HP-UX',
        OSVERSION  => $kernelVersion . ' ' . $OSLicense,
        OSCOMMENTS => $kernelRelease,
    });

    $inventory->setOperatingSystem({
        NAME           => 'HP-UX',
        VERSION        => $kernelRelease,
        KERNEL_VERSION => $kernelRelease,
    });
}

1;
