package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::MeshCentral;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;
    my $logger    = $params{logger};

    if (OSNAME eq 'MSWin32') {

        GLPI::Agent::Tools::Win32->use();

        my $key = getRegistryKey(
            path        => "HKEY_LOCAL_MACHINE/SOFTWARE/Open Source/Mesh Agent",
            required    => [ qw/NodeId/ ],
            maxdepth    => 1,
            logger      => $params{logger}
        );

        return $key && (keys %$key);

    } elsif (OSNAME eq 'darwin') {
        return canRun('defaults') && Glob(
            "/Library/LaunchDaemons/meshagent*.plist"
        );
    }

    return Glob('/etc/systemd/system/meshagent.service');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $nodeId = _getNodeId()
        or return;

    $inventory->addEntry(
        section => 'REMOTE_MGMT',
        entry   => {
            ID   => $nodeId,
            TYPE => 'meshcentral'
        }
    );
}

sub _getNodeId {
    my (%params) = @_;

    return _winBased() if OSNAME eq 'MSWin32';
    return _darwinBased() if OSNAME eq 'darwin';
    return _linuxBased();
}

sub _winBased {
    my (%params) = @_;

    my $nodeId = getRegistryValue(
        path        => "HKEY_LOCAL_MACHINE/SOFTWARE/Open Source/Mesh Agent/NodeId",
        logger      => $params{logger}
    );

    return $nodeId; 
}

sub _linuxBased {
    my (%params) = @_;    

    my $command = getFirstLine(
            file    => "/etc/systemd/system/meshagent.service",
            pattern => qr/Ex.*=(.*)\s\-/,
            logger  => $params{logger},
    );

    return getFirstLine(
        command => "${command} -nodeid");
}

sub _darwinBased {
    my (%params) = @_;    

    return getFirstLine(
        command => "/usr/local/mesh_services/meshagent/meshagent_osx64 -nodeid",
    );
}

1;
