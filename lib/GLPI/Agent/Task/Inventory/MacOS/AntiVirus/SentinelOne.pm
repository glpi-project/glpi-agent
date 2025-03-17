package GLPI::Agent::Task::Inventory::MacOS::AntiVirus::SentinelOne;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

my $command = '/Library/Sentinel/sentinel-agent.bundle/Contents/MacOS/sentinelctl';

sub isEnabled {
    return canRun($command);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getSentinelOne(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME} ".($antivirus->{VERSION}? " v$antivirus->{VERSION}":""))
            if $logger;
    }
}

sub _getSentinelOne {
    my (%params) = @_;

    my $antivirus = {
        COMPANY     => "Sentinel Labs Inc.",
        NAME        => "SentinelOne EPP",
        ENABLED     => 0,
    };

    # Support file case for unittests if basefile is provided
    if (empty($params{basefile})) {
        $params{command} = "\"$command\" version";
    } else {
        $params{file} = $params{basefile}."-version";
    }
    my $version = getFirstMatch(
        pattern => qr/^SentinelOne.* ([0-9.]+)$/,
        %params
    );
    $antivirus->{VERSION} = $version if $version;

    # Support file case for unittests if basefile is provided
    if (empty($params{basefile})) {
        $params{command} = "\"$command\" status";
    } else {
        $params{file} = $params{basefile}."-status";
    }
    my @lines = getAllLines(%params);
    $antivirus->{ENABLED} = 1 if first { /^\s+Protection:\s+enabled$/i } @lines;

    return $antivirus;
}

1;
