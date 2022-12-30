package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::AnyDesk;

# Based on the work done by Ilya published on no more existing https://fusioninventory.userecho.com site

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub _get_anydesk_config {
    my @configs = ();
    if (OSNAME eq 'MSWin32') {
        if (has_folder('C:\ProgramData\AnyDesk')) {
            push @configs, Glob('C:\ProgramData\AnyDesk\ad_*\system.conf');
            push @configs, 'C:\ProgramData\AnyDesk\system.conf';
        }
    } else {
        push @configs, Glob('/etc/anydesk_ad_*/system.conf');
        push @configs, '/etc/anydesk/system.conf';
    }
    return grep { canRead($_) } @configs;
}

sub isEnabled {
    return _get_anydesk_config() ? 1 : 0;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $conf (_get_anydesk_config()) {
        my $AnyDeskID = getFirstMatch(
            file    => $conf,
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
            $logger->debug('AnyDesk ID not found in '.$conf) if $logger;
        }
    }
}

1;
