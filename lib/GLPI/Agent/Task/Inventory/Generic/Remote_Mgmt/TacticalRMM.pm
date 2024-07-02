package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::TacticalRMM;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    if (OSNAME eq 'MSWin32') {

        GLPI::Agent::Tools::Win32->use();

        my $key = getRegistryKey(
            path        => "HKEY_LOCAL_MACHINE/SOFTWARE/TacticalRMM/",
            # Important for remote inventory optimization
            required    => [ qw/AgentId/ ],
            maxdepth    => 1,
            logger      => $params{logger}
        );

        return 1 if defined($key);

    }

    return 0;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};
    my $agentId   = _getAgentId(logger => $logger)
        or return;

    $inventory->addEntry(
        section => 'REMOTE_MGMT',
        entry   => {
            ID   => $agentId,
            TYPE => 'tacticalrmm'
        }
    );
}

sub _getAgentId {
    my (%params) = @_;

    return _winBased(%params) if OSNAME eq 'MSWin32';
}

sub _winBased {
    my (%params) = @_;

    my $agentId = getRegistryValue(
        path        => "HKEY_LOCAL_MACHINE/SOFTWARE/TacticalRMM/AgentId",
        logger      => $params{logger}
    );

    return $agentId;
}

1;
