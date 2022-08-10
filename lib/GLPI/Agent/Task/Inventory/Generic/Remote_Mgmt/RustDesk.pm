package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::RustDesk;

# Based on the work done by Ilya published on no more existing https://fusioninventory.userecho.com site

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub _get_rustdesk_config {
    return OSNAME eq 'MSWin32' ?
        'C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml' :
        '/root/.config/rustdesk/RustDesk.toml';
}

sub isEnabled {
    return has_file(_get_rustdesk_config());
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $conf = _get_rustdesk_config();
    my $RustDeskID = getFirstMatch(
        file    => $conf,
        logger  => $logger,
        pattern => qr/^id\s*=\s*'(.*)'$/
    );

    if (defined($RustDeskID)) {
        $logger->debug('Found RustDesk ID : ' . $RustDeskID) if $logger;

        $inventory->addEntry(
            section => 'REMOTE_MGMT',
            entry   => {
                ID   => $RustDeskID,
                TYPE => 'rustdesk'
            }
        );
    } else {
        $logger->debug('RustDesk ID not found in '.$conf) if $logger;
    }
}

1;
