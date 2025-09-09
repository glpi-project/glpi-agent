package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::RuDesktop;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub _get_rudesktop_path {
    return OSNAME eq 'MSWin32' ?
        'C:\Program Files\RuDesktop\rudesktop.exe' :
        'rudesktop';
}

sub isEnabled {
    my $path = _get_rudesktop_path();
    return canRun($path);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $rudesktop_path = _get_rudesktop_path();
    my $command = OSNAME eq 'MSWin32' ? "\"$rudesktop_path\"" : $rudesktop_path;
    $command .= " --get-id";

    my $RudesktopID = getFirstMatch(
        command => $command,
        logger  => $logger,
        pattern => qr/^(\d+)$/
    );

    if (defined($RudesktopID)) {
        $logger->debug("Found Rudesktop ID: $RudesktopID") if $logger;

        $inventory->addEntry(
            section => 'REMOTE_MGMT',
            entry   => {
                ID   => $RudesktopID,
                TYPE => 'rudesktop'
            }
        );
    } else {
        $logger->debug("Rudesktop ID not found (command: $command)") if $logger;
    }
}

1;
