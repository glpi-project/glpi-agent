package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::MeshCentral;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub isEnabled {
    return OSNAME eq 'MSWin32' ?
        canRun("C:\\Program Files\\Mesh Agent\\MeshAgent.exe") :
        canRun('/usr/local/mesh_services/meshagent/meshagent');
}

sub _getNodeId {
    return OSNAME eq 'MSWin32' ?
    getFirstLine(
        command => 'C:\\Program Files\\Mesh Agent\\MeshAgent.exe -nodeid') :
    getFirstLine(
        command => '/usr/local/mesh_services/meshagent/meshagent -nodeid');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $nodeId = _getNodeId();

    return unless $nodeId;

    $inventory->addEntry(
        section => 'REMOTE_MGMT',
        entry   => {
            ID   => $nodeId,
            TYPE => 'meshcentral'
        }
    );
}

1;
