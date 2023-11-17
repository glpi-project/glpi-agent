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
	my @command1 = getAllLines(command => '/opt/sentinelone/bin/sentinelctl version');
	my @command2 = getAllLines(command => '/opt/sentinelone/bin/sentinelctl engines status');
	my @command3 = getAllLines(command => '/opt/sentinelone/bin/sentinelctl control status');
	my @command4 = getAllLines(command => '/opt/sentinelone/bin/sentinelctl management status');

    my @output = (@command1,@command2,@command3,@command4)
        or return;

    my $av = {
        NAME     => 'SentinelAgent',
        COMPANY  => 'SentinelOne',
        ENABLED => 0,
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
        # Not this item as SentinelOne antivirus is not using the traditional signatures definition model
		# } elsif ($key eq "Last security content update" && $value =~ /^(\d{4}-\d+-\d+) at/) {
        #    $av->{BASE_CREATION} = $1;
        }
    }

    return $av;
}

1;
