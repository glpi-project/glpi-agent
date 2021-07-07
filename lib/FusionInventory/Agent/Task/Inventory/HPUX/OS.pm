package FusionInventory::Agent::Task::Inventory::HPUX::OS;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Operating system informations
    my $kernelRelease = getFirstLine(
        logger  => $logger,
        command => 'uname -r'
    );

    $inventory->setOperatingSystem({
        NAME           => 'HP-UX',
        VERSION        => $kernelRelease,
        KERNEL_VERSION => $kernelRelease,
    });
}

1;
