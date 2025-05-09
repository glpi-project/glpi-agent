package GLPI::Agent::Task::Inventory::Linux::AntiVirus::DrWeb;

use strict;
use warnings;
use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use Time::Piece;

sub isEnabled {
    return canRun('drweb-ctl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getDrWebInfo(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME}" .
            ($antivirus->{VERSION} ? " v$antivirus->{VERSION}" : "") .
            ($antivirus->{ENABLED} ? " [ENABLED]" : " [DISABLED]") .
            ($antivirus->{EXPIRATION} ? " Expires: $antivirus->{EXPIRATION}" :
             $antivirus->{SERVER_LICENSE} ? " [Server-managed license]" : ""))
            if $logger;
    }
}

sub _getDrWebInfo {
    my (%params) = @_;
    my $logger = $params{logger};

    my $av = {
        NAME     => 'Dr.Web',
        COMPANY  => 'Doctor Web',  
        ENABLED  => 0,               
        UPTODATE => 0,               
    };

    # 1. Get product version information
    my $version_output = getFirstLine(
        command => 'drweb-ctl --version 2>/dev/null',
        %params
    );

    # Extract version number if available
    if ($version_output && $version_output =~ /drweb-ctl\s+([\d.]+)/) {
        $av->{VERSION} = $1;
    }

    # 2. Check if Dr.Web service is running
    my $service_status = getFirstLine(
        command => 'systemctl is-active drweb-configd.service 2>/dev/null',
        %params
    );
    # Set ENABLED flag based on service status
    $av->{ENABLED} = $service_status && $service_status eq 'active' ? 1 : 0;

    # 3. Get antivirus database information
    my @baseinfo = getAllLines(
        command => 'drweb-ctl baseinfo 2>/dev/null',
        %params
    );

    my ($db_timestamp);
    # Parse database timestamp from output
    foreach my $line (@baseinfo) {
        if ($line =~ /Virus database timestamp:\s+(.+)/) {
            $db_timestamp = $1;
            $av->{BASE_VERSION} = $1;  # Store raw timestamp string
            last;
        }
    }

    # Check if database is up-to-date (within 2 days)
    if ($db_timestamp) {
        eval {
            my $db_time = Time::Piece->strptime($db_timestamp, "%Y-%b-%d %H:%M:%S");
            my $diff = time() - $db_time->epoch;
            $av->{UPTODATE} = ($diff <= 172800) ? 1 : 0;  # 172800 seconds = 2 days
        };
        $av->{UPTODATE} = 0 if $@;
    }

    # 4. Get license information
    my @license_info = getAllLines(
        command => 'drweb-ctl license 2>/dev/null',
        %params
    );

    # Parse license information
    foreach my $line (@license_info) {
        if ($line =~ /expires\s+(\d{4}-\w{3}-\d{1,2})(?:\s|$)/i) {
            eval {
                my $expire_time = Time::Piece->strptime($1, "%Y-%b-%d");
                $av->{EXPIRATION} = $expire_time->strftime("%Y-%m-%d"); 
            };
            if ($@) {
                $logger->debug("Failed to parse license expiration: $@");
            }
            last;
        }
        elsif ($line =~ /license is granted by the protection server/i) {
            $av->{SERVER_LICENSE} = 1;
            last;
        }
    }

    return $av;
}

1;