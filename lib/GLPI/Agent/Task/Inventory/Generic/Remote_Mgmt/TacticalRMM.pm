package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::TacticalRMM;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use Cpanel::JSON::XS;

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

        return 1 if defined($key) && keys(%{$key});

    } elsif (OSNAME eq 'linux') {
        return 1 if has_file('/etc/tacticalagent');
    } elsif (OSNAME eq 'darwin') {
        return 1 if has_file('/private/etc/tacticalagent');
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
    return _linuxBased(%params) if OSNAME eq 'linux';
    return _macosBased(%params) if OSNAME eq 'darwin';
}

sub _macosBased {
    my (%params) = @_;

    my $config = getAllLines(
        file    => '/private/etc/tacticalagent',
        %params
    );

    my $json = decode_json($config)
        or return;

    return $json->{agentid};
}

sub _linuxBased {
    my (%params) = @_;

    my $config = getAllLines(
        file    => '/etc/tacticalagent',
        %params
    );

    my $json = decode_json($config)
        or return;

    return $json->{agentid};
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

    my $command = OSNAME eq 'MSWin32' ?
        '"C:\\Program Files\\TacticalAgent\\tacticalrmm.exe" --version' :
        canRun("rmmagent") ? "rmmagent --version" :
        canRun("tacticalagent") ? "tacticalagent --version" :
        OSNAME eq 'darwin' ? "/opt/tacticalagent/tacticalagent --version" :
        "/usr/local/bin/rmmagent --version";

    # On windows, the command seems to output a BOM on the first line
    my $line = getSanitizedString(getFirstLine(
        command => $command,
        %params
    ));

    return unless $line;
    return $line =~ /Tactical RMM Agent:\s+([0-9.]+)/i;
}

1;
