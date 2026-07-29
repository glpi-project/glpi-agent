package GLPI::Agent::Task::Inventory::Linux::AntiVirus::Wazuh;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

# Path from agent install
use constant    wazuh_control   => '/var/ossec/bin/wazuh-control';

sub isEnabled {
    return canRun(wazuh_control);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getWazuhInfo(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME}" . ($antivirus->{VERSION} ? " v$antivirus->{VERSION}" : ""))
            if $logger;
    }
}

sub _getWazuhInfo {
    my (%params) = @_;

    my $logger = $params{logger};

    # For tests, the following parameters can be set in %params:
    # - wazuh_version:  output of /var/ossec/bin/wazuh-control info
    # - wazuh_status:   output of /var/ossec/bin/wazuh-control status

    # get version from wazuh-control info
    my $version = getFirstMatch(
        command => $params{wazuh_version} ? '' : [ wazuh_control, 'info' ],
        pattern => qr/WAZUH_VERSION="v([^"]+)"/,
        logger  => $logger,
        string  => $params{wazuh_version}
    );

    # Get service status from wazuh-control status
    my $is_enabled = scalar(getFirstMatch(
        command => $params{wazuh_status} ? '' : [ wazuh_control, 'status' ],
        pattern => qr/wazuh-agentd is running/i,
        logger  => $logger,
        string  => $params{wazuh_status}
    ));

    return {
        NAME         => 'Wazuh Agent',
        COMPANY      => 'Wazuh, Inc.',
        VERSION      => $version // '',
        ENABLED      => $is_enabled,
        # Wazuh control update from central
        # So, if agent is enable its asume up-to-date.
        UPTODATE     => $is_enabled,
    };
}

1;
