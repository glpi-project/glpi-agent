package FusionInventory::Agent::Task::Inventory::Generic::Environment;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

use constant    category    => "environment";

sub isEnabled {
    my (%params) = @_;

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
