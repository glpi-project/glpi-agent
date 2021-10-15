package FusionInventory::Agent::Task::Inventory::Generic::Hostname;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Hostname;

use constant    category    => "hardware";

sub isEnabled {
    # We use WMI for Windows because of charset issue
    return OSNAME ne 'MSWin32';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # keep just the hostname
    my $hostname = getHostname(short => 1);

    $inventory->setHardware({NAME => $hostname});
}

1;
