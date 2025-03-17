package GLPI::Agent::Task::Inventory::Generic::Hostname;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Hostname;

use constant    category    => "hardware";

sub isEnabled {
    # We use WMI for Windows because of charset issue
    return OSNAME ne 'MSWin32';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $assetname_support = $params{'assetname_support'};

    # use the hostname as desired
    my $hostname;
    if ($assetname_support == 2) {
        $hostname = getHostname();
    } elsif ($assetname_support == 3) {
        $hostname = getHostname(fqdn => 1);
    } else {
        $hostname = getHostname(short => 1);
    }

    $inventory->setHardware({NAME => $hostname});
}

1;
