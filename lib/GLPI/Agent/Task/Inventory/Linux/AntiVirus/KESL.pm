package GLPI::Agent::Task::Inventory::Linux::AntiVirus::KESL;

use strict;
use warnings;
use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use Time::Piece;

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
    my $logger = $params{logger};

    my $av = {
        NAME     => 'Kaspersky Endpoint Security for Linux', 
        COMPANY  => 'Kaspersky Lab',
        ENABLED  => 0,               
        UPTODATE => 0,
    };

    # 1. Check if KESL service is running via systemd
    my $service_status = getFirstLine(
        command => 'systemctl is-active kesl.service 2>/dev/null',
        %params
    );
    # Set ENABLED flag based on service status (active = 1, inactive = 0)
    $av->{ENABLED} = $service_status && $service_status eq 'active' ? 1 : 0;

    # 2. Get product version information
    my $version_output = getFirstLine(
        command => 'kesl-control --app-info 2>/dev/null | grep -E "Version|Версия"',
        %params
    );
    # Extract version number from either English or Russian output
    if ($version_output && $version_output =~ /(?:Version|Версия):\s+([\d.]+)/) {
        $av->{VERSION} = $1;
    }

    # 3. Get license expiration information
    my $license_output = getFirstLine(
        command => 'kesl-control --app-info 2>/dev/null | grep -E "License expiration date|Дата окончания срока действия лицензии"',
        %params
    );
    # Parse expiration date from either English or Russian output
    if ($license_output && $license_output =~ /(?:License expiration date|Дата окончания срока действия лицензии):\s+([\d-]+)/) {
        eval {
            my $expire_time = Time::Piece->strptime($1, "%Y-%m-%d");
            $av->{EXPIRATION} = $expire_time->strftime("%Y-%m-%d");
        };
        if ($@) {
            $logger->debug("Failed to parse license expiration: $@");
        }
    }

    # 4. Get antivirus database update information
    my $db_date_output = getFirstLine(
        command => 'kesl-control --app-info 2>/dev/null | grep -E "Last release date of databases|Дата последнего выпуска баз приложения"',
        %params
    );
    # Parse database timestamp from either English or Russian output
    if ($db_date_output && $db_date_output =~ /(?:Last release date of databases|Дата последнего выпуска баз приложения):\s+([\d-]+\s[\d:]+)/) {
        eval {
            my $db_time = Time::Piece->strptime($1, "%Y-%m-%d %H:%M:%S");
            my $diff = time() - $db_time->epoch;
            # Mark as up-to-date if databases are less than 2 days old (172800 seconds)
            $av->{UPTODATE} = ($diff <= 172800) ? 1 : 0;
        };
        if ($@) {
            $logger->debug("Failed to parse database timestamp: $@");
        }
    }

    return $av;
}

1;