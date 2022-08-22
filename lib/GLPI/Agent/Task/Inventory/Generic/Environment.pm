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
        OSNAME ne 'MSWin32'
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my %env;
    if ($inventory->getRemote()) {
        foreach my $line (getAllLines(
            command => 'env',
            logger  => $params{logger},
        )) {
            next unless $line =~ /^(\w+)=(.*)$/;
            next unless $1 ne '_' && defined($2);
            $env{$1} = $2;
        }
    } else {
        %env = %ENV;
    }

    foreach my $key (keys %env) {
        $inventory->addEntry(
            section => 'ENVS',
            entry   => {
                KEY => $key,
                VAL => $env{$key}
            }
        );
    }
}

1;
