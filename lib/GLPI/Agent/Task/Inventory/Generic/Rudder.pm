package GLPI::Agent::Task::Inventory::Generic::Rudder;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

use constant    category    => "rudder";

sub isEnabled {
    return canRead(getUuidFile());
}

sub getUuidFile {
    return ((OSNAME eq 'MSWin32') ? 'C:\Program Files\Rudder\etc\uuid.hive' : '/opt/rudder/etc/uuid.hive');
}

sub doInventory {
    my (%params) = @_;

    my $inventory    = $params{inventory};
    my $logger       = $params{logger};

    my $uuid_hive = getUuidFile();

    # Get Rudder UUID
    my $Uuid = getFirstLine(
        logger => $logger, file => $uuid_hive
    );
    # Get all agents running on that machine
    my @agents = _manageAgent(
        logger => $logger
    );
    # Get machine hostname
    my $command = OSNAME eq 'linux' ? 'hostname --fqdn' : 'hostname';
    my $hostname = getFirstLine(
        logger => $logger, command => $command
    );
    # Get server roles
    my @serverRoles = _listServerRoles();

    # Get agent capabilities
    my @agentCapabilities = _listAgentCapabilities();

    my $rudder = {
        HOSTNAME => $hostname,
        UUID => $Uuid,
        AGENT => \@agents,
        SERVER_ROLES => { SERVER_ROLE => \@serverRoles },
        AGENT_CAPABILITIES => { AGENT_CAPABILITY => \@agentCapabilities },
    };

    $inventory->addEntry(
        section => 'RUDDER', entry => $rudder
    );
}

sub _listServerRoles {
    my $server_roles_dir = (OSNAME eq 'MSWin32') ? 'C:\Program Files\Rudder\etc\server-roles.d' : '/opt/rudder/etc/server-roles.d';
    my @server_roles;

    if (has_folder("$server_roles_dir")) {
        # List each file in the server-roles directory, each file name is a role
        foreach my $file (Glob("$server_roles_dir/*")) {
            push @server_roles, $file;
        }
    }
    return @server_roles;
}

sub _listAgentCapabilities {
   my $capabilities_file = (OSNAME eq 'MSWin32') ? 'C:\Program Files\Rudder\etc\agent-capabilities' : '/opt/rudder/etc/agent-capabilities';
   my @capabilities;

    # List agent capabilities, one per line in the file
    foreach my $row (getAllLines($capabilities_file)) {
        chomp $row;
        push @capabilities, $row;
    }

    return @capabilities;
}

sub _manageAgent {
    my %params = @_;
    my $logger = $params{logger};
    my @agents;

    # Potential agent directory candidates
    my %agent_candidates = ( '/var/rudder/cfengine-community' => 'cfengine-community',
                             '/var/rudder/cfengine-nova'      => 'cfengine-nova',
                             'C:/Program Files/Cfengine'      => 'cfengine-nova',
                           );

    foreach my $candidate (keys(%agent_candidates)){

        # Verify if the candidate is installed and configured
        next unless ( has_file("${candidate}/policy_server.dat") );

        # Get a list of useful file paths to key Rudder components
        my $agent_name           = "$agent_candidates{${candidate}}";
        my $server_hostname_file = "${candidate}/policy_server.dat";
        my $uuid_file            = "${candidate}/rudder-server-uuid.txt";
        my $cfengine_key_file    = "${candidate}/ppkeys/localhost.pub";

        # get policy server hostname
        my $serverHostname = getFirstLine (
            logger => $logger,
            file   => $server_hostname_file
        );
        chomp $serverHostname;

        # Get the policy server UUID
        #
        # The default file is no longer /var/rudder/tmp/uuid.txt since the
        # change in http://www.rudder-project.org/redmine/issues/2443.
        # We gracefully fallback to the old default if the new file cannot
        # be found.
        my $serverUuid = getFirstLine (
            logger => $logger,
            file => ( has_file("$uuid_file") ) ? $uuid_file : "/var/rudder/tmp/uuid.txt"
        );
        chomp $serverUuid;

        # get CFengine public key
        my $cfengineKey = getAllLines(
            file => $cfengine_key_file
        );

        # get owner name
        my $owner = getFirstLine (
            logger => $logger,
            command => 'whoami'
        );

        # build agent from datas
        my $agent = {
            AGENT_NAME             => $agent_name,
            POLICY_SERVER_HOSTNAME => $serverHostname,
            CFENGINE_KEY           => $cfengineKey,
            OWNER                  => $owner,
            POLICY_SERVER_UUID     => $serverUuid,
        };

        push @agents, $agent;

    }

    return @agents;
}

1;
