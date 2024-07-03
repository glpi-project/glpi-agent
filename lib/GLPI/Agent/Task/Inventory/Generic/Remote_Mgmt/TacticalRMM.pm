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

    my $version   = _getVersion(logger => $logger);
    my $agentId   = _getAgentId(logger => $logger)
        or return;

    my $mgmt = {
        ID      => $agentId,
        TYPE    => 'tacticalrmm',
    };
    $mgmt->{VERSION} = $version if $version;

    $inventory->addEntry(
        section => 'REMOTE_MGMT',
        entry   => $mgmt,
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

sub _getVersion {
    my (%params) = @_;

    my $version;

    if (OSNAME eq 'MSWin32') {
        my $command = "C:\\Program Files\\TacticalAgent\\tacticalrmm.exe";
        if (canRun($command)) {
            $version = getFirstMatch(
                command => "\"$command\" --version",
                pattern => qr/^Tactical RMM Agent:\s+(\S+)/i,
                logger  => $params{logger}
            );
        }
    }

    return $version;
}

1;
