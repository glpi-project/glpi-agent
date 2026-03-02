package GLPI::Agent::Task::Inventory::MacOS::AntiVirus::WithSecure;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;

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

        $logger->debug2("Added $antivirus->{NAME}".($antivirus->{VERSION}? " v$antivirus->{VERSION}":""))
            if $logger;
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
            $antivirus->{BASE_VERSION} = $1;
        }
    }

    # is wsavd process running?
    my ($ps) = getProcesses(
        filter => qr/wsavd/,
        logger => $logger
    );
    $antivirus->{ENABLED} = $ps ? 1 : 0;

    return $antivirus;
}

1;
