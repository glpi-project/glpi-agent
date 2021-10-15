package FusionInventory::Agent::Task::Inventory::Generic::Arch;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return canRun('arch');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $arch = getFirstLine( command => 'arch' );

    $inventory->setOperatingSystem({
        ARCH     => $arch
    });

}

1;
