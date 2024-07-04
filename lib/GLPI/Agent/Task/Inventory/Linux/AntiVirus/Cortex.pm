package GLPI::Agent::Task::Inventory::Linux::AntiVirus::Cortex;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

my $command = '/opt/traps/bin/cytool';

sub isEnabled {
    return canRun($command);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getCortex(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME}".($antivirus->{VERSION}? " v$antivirus->{VERSION}":""))
            if $logger;
    }
}

sub _getCortex {
    my (%params) = @_;

    my $antivirus = {
        COMPANY     => "Palo Alto Networks",
        NAME        => "Cortex XDR",
        ENABLED     => 0,
    };

    # Support file case for unittests if basefile is provided
    if (empty($params{basefile})) {
        $params{command} = "\"$command\" info";
    } else {
        $params{file} = $params{basefile}."-info";
    }
    my $version = getFirstMatch(
        pattern => qr/^Cortex XDR .* ([0-9.]+)$/,
        %params
    );
    $antivirus->{VERSION} = $version if $version;

    # Support file case for unittests if basefile is provided
    if (empty($params{basefile})) {
        $params{command} = "\"$command\" info query";
    } else {
        $params{file} = $params{basefile}."-info-query";
    }
    my $base_version = getFirstMatch(
        pattern => qr/^Content Version:\s+(\S+)$/i,
        %params
    );
    $antivirus->{BASE_VERSION} = $base_version if $base_version;

    # Support file case for unittests if basefile is provided
    if (empty($params{basefile})) {
        $params{command} = "\"$command\" runtime query";
    } else {
        $params{file} = $params{basefile}."-runtime-query";
    }
    my $status = getFirstMatch(
        pattern => qr/^\s*pmd\s+\S+\s+\S+\s+(\S+)\s/i,
        %params
    );
    $antivirus->{ENABLED} = 1 if $status && $status =~ /^Running$/i;

    return $antivirus;
}

1;
