package GLPI::Agent::Task::Inventory::Generic::Environment;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "environment";

sub isEnabled {
    return
        # We use WMI for Windows because of charset issue
        $OSNAME ne 'MSWin32'
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $key (keys %ENV) {
        $inventory->addEntry(
            section => 'ENVS',
            entry   => {
                KEY => $key,
                VAL => $ENV{$key}
            }
        );
    }
}

1;
