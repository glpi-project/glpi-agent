package GLPI::Agent::Task::Inventory::Linux::AntiVirus::KESL;

use strict;
use warnings;
use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('kesl-control');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getKESLInfo(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME}" .
            ($antivirus->{VERSION} ? " v$antivirus->{VERSION}" : "") .
            ($antivirus->{ENABLED} ? " [ENABLED]" : " [DISABLED]") .
            ($antivirus->{EXPIRATION} ? " Expires: $antivirus->{EXPIRATION}" : ""))
            if $logger;
    }
}

sub _getKESLInfo {
    my (%params) = @_;

    my $av = {
        NAME     => 'Kaspersky Endpoint Security for Linux',
        COMPANY  => 'Kaspersky Lab',
        ENABLED  => 0,
        UPTODATE => 0,
    };

    my $service_status = getFirstLine(
        command => 'systemctl is-active kesl.service',
        %params
    );
    $av->{ENABLED} = $service_status && $service_status eq 'active' ? 1 : 0;

    my @app_info = getAllLines(
        command => 'kesl-control --app-info',
        %params
    );

    foreach my $line (@app_info) {

        if (!$av->{VERSION} && $line =~ /^Version:\s+([\d.]+)/) {
            $av->{VERSION} = $1;
            next;
        }

        if (!$av->{EXPIRATION} && $line =~ /license expiration date:\s+([\d-]+)/i) {
            $av->{EXPIRATION} = $1;
            next;
        }

        if (!$av->{BASE_VERSION} && $line =~ /^Last release date of databases:\s+([\d-]+)/) {
            $av->{BASE_VERSION} = $1;
            next;
        }
    }

    return $av;
}

1;
