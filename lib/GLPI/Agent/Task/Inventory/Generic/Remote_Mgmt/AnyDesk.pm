package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::AnyDesk;

# Based on the work done by Ilya published on no more existing https://fusioninventory.userecho.com site

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub _get_anydesk_config {
    my @configs;
    if (OSNAME eq 'MSWin32') {
        if (has_folder('C:\ProgramData\AnyDesk')) {
            push @configs, Glob('C:\ProgramData\AnyDesk\ad_*\system.conf');
            push @configs, 'C:\ProgramData\AnyDesk\system.conf'
                unless @configs;
        }
    } else {
        @configs = qw{
            /etc/anydesk/system.conf
        };
    }
    return first { has_file($_) } @configs;
}

sub isEnabled {
    return _get_anydesk_config() ? 1 : 0;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $AnyDeskID = getFirstMatch(
        file    => _get_anydesk_config(),
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
