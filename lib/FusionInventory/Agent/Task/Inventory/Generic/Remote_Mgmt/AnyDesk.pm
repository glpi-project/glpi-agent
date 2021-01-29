package FusionInventory::Agent::Task::Inventory::Generic::Remote_Mgmt::AnyDesk;

# Based on the work done by Ilya
# See https://fusioninventory.userecho.com/en/communities/1/topics/87-support-for-anydesk-remote-desktop

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

sub _anydesk_config {
    return 'C:\ProgramData\AnyDesk\system.conf' if $OSNAME eq 'MSWin32';
    return '/etc/anydesk/system.conf';
}

sub isEnabled {
    return -r _anydesk_config() ? 1 : 0;
}

sub isEnabledForRemote {
    # Testing if a file is existing is not supported for WMI remote inventory
    return 0;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $AnyDeskID = getFirstMatch(
        file    => _anydesk_config(),
        logger  => $logger,
        pattern => qr/^ad.anynet.id=(\S+)/
    );

    if (defined($AnyDeskID)) {
        $logger->debug('Found AnyDesk ID : ' . $AnyDeskID) if $logger;

        $inventory->addEntry(
            section => 'REMOTE_MGMT',
            entry   => {
                ID   => $AnyDeskID,
                TYPE => 'anydesk'
            }
        );
    } else {
        $logger->debug('AnyDesk ID not found') if $logger;
    }
}

1;
