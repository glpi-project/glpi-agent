package FusionInventory::Agent::Task::Inventory::AIX::Hardware;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $unameL = Uname("-L");
    # LPAR partition can access the serial number of the host computer
    if ($unameL && $unameL =~ /^(\d+)\s+(\S+)/) {
        $inventory->setHardware({
            VMSYSTEM    => "AIX_LPAR",
        });
    }
}

1;
