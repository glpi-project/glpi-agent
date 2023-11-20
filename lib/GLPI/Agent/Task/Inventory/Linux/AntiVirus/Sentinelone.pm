package GLPI::Agent::Task::Inventory::Linux::AntiVirus::Sentinelone;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use UNIVERSAL::require;

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('/opt/sentinelone/bin/sentinelctl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getSentineloneInfo(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME}" . ($antivirus->{VERSION} ? " v$antivirus->{VERSION}" : ""))
            if $logger;
    }
}

sub _getSentineloneInfo {
    my (%params) = @_;

    my $cmd = '/opt/sentinelone/bin/sentinelctl';

    my @output = getAllLines(
        command => "$cmd version && $cmd engines status && $cmd control status && $cmd management status",
        %params
    )
        or return;

    my $av = {
        NAME     => 'SentinelAgent',
        COMPANY  => 'SentinelOne',
        ENABLED  => 0,
        UPTODATE => 0,
    };

    foreach my $line (@output) {
        my ($key, $value) = $line =~ /(.+)(?:: |(?<!\s)\s{2,})(.*)/
            or next;
        if ($key eq "Agent version") {
            $av->{VERSION} = $value;
        } elsif ($key eq "DFI library version") {
            $av->{BASE_VERSION} = $value;
        } elsif ($key eq "Agent state") {
            $av->{ENABLED} = $value eq "Enabled" ? 1 : 0;
        } elsif ($key eq "Connectivity") {
            # SentinelAgent does not directly report "uptodate" status but we can assume it is updated if the cloud connectivity is working.
            $av->{UPTODATE} = $value eq "On" ? 1 : 0;
        }
    }

    return $av;
}

1;
