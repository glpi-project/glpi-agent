package GLPI::Agent::Task::Inventory::HPUX::OS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Operating system informations
    my $kernelRelease = Uname("-r");

    $inventory->setOperatingSystem({
        NAME           => 'HP-UX',
        VERSION        => $kernelRelease,
        KERNEL_VERSION => $kernelRelease,
    });
}

1;
