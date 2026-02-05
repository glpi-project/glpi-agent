package GLPI::Agent::Task::Inventory::MacOS::AntiVirus::WithSecure;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

# Maximum number of days for the AV database to be considered as "up-to-date"
use constant MAX_AGE_DAYS => 2;

sub isEnabled {
    return canRun('/usr/local/bin/wsav');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getWithSecureClient(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2(
            "Added $antivirus->{NAME}" .
            ($antivirus->{VERSION} ? " v$antivirus->{VERSION}" : "") .
            " (enabled=" . ($antivirus->{ENABLED} ? "yes" : "no") .
            ", uptodate=" . ($antivirus->{UPTODATE} ? "yes" : "no") . ")"
        ) if $logger;
    }
}

sub _getWithSecureClient {
    my (%params) = @_;
    my $logger = $params{logger};

    my $antivirus = {
        NAME     => "WithSecure Client Security for Mac",
        COMPANY  => "WithSecure",
        ENABLED  => 0,
        UPTODATE => 0,
    };

    # wsav --version output
    my @lines = getAllLines(
        command => '/usr/local/bin/wsav --version',
        logger  => $logger
    );
    return unless @lines;

    foreach my $line (@lines) {
        chomp($line);

        # Product version example:
        # "WithSecure™ ClientSecurity version 16.02"
        if ($line =~ /ClientSecurity\s+version\s+([\d.]+)/i) {
            $antivirus->{VERSION} = $1;
            next;
        }

        # Database version example:
        # "Database version: 2026-02-05_02"
        if ($line =~ /^Database\s+version:\s*(\S+)/i) {
            my $dbver = $1;

            $antivirus->{BASE_VERSION} = $dbver;

            if ($dbver =~ /^(\d{4})-(\d{2})-(\d{2})/) {
                my ($year, $month, $day) = ($1, $2, $3);

                my $db_time = _parse_date($year, $month, $day);

                if (defined $db_time) {
                    my $age_days = (time() - $db_time) / 86400;

                    # Useful debug info
                    $logger->debug2(
                        "WithSecure DB version=$dbver parsed_date=$year-$month-$day " .
                        "epoch=$db_time age_days=$age_days"
                    ) if $logger;

                    $antivirus->{UPTODATE} = ($age_days < MAX_AGE_DAYS) ? 1 : 0;

                    # AV database create date (ISO format, clean)
                    $antivirus->{BASE_CREATION} = sprintf("%04d-%02d-%02d", $year, $month, $day);
                }
                else {
                    $logger->debug2("WithSecure: unable to parse database date from '$dbver'")
                        if $logger;
                }
            }
            else {
                $logger->debug2("WithSecure: database version format not recognized: '$dbver'")
                    if $logger;
            }

            next;
        }
    }

    # is wsavd process running?
    my $ps = getFirstLine(command => '/bin/ps aux | /usr/bin/grep "[w]savd"');
    $antivirus->{ENABLED} = $ps ? 1 : 0;

    return $antivirus;
}

sub _parse_date {
    my ($year, $month, $day) = @_;

    my $time = eval {
        require Time::Local;
        Time::Local::timelocal(0, 0, 0, $day, $month - 1, $year);
    };

    # if Time::Local worked, return the result
    return $time if defined $time && !$@;

    # fallback if Time::Local unavailable or error
    my @now = localtime();
    my $current_year = $now[5] + 1900;

    my $days_diff = ($current_year - $year) * 365
                  + (($now[4] + 1) - $month) * 30
                  + ($now[3] - $day);

    return time() - ($days_diff * 86400);
}

1;

