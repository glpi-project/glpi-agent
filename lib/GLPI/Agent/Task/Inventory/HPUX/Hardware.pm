package GLPI::Agent::Task::Inventory::HPUX::Hardware;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $hardware = {};

    if (canRun('/usr/contrib/bin/machinfo')) {
        my $info = getInfoFromMachinfo(logger => $logger);
        $hardware->{UUID} = uc($info->{'Platform info'}->{'machine id number'});
    }

    $inventory->setHardware($hardware) if keys(%{$hardware});
}

1;
