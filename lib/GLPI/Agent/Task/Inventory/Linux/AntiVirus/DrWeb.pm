package GLPI::Agent::Task::Inventory::Linux::AntiVirus::DrWeb;

use strict;
use warnings;
use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

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
            ($antivirus->{ENABLED} ? " [ENABLED]" : " [DISABLED]"))
            if $logger;
    }
}

sub _getDrWebInfo {
    my (%params) = @_;

    my $av = {
        NAME     => 'Dr.Web',
        COMPANY  => 'Doctor Web',
        ENABLED  => 0,
        UPTODATE => 0,
    };

    my $version_output = getFirstLine(
        command => 'drweb-ctl --version',
        %params
    );

    if ($version_output && $version_output =~ /drweb-ctl\s+([\d.]+)/) {
        $av->{VERSION} = $1;
    }

    my $service_status = getFirstLine(
        command => 'systemctl is-active drweb-configd.service',
        %params
    );
    $av->{ENABLED} = $service_status && $service_status eq 'active' ? 1 : 0;

    my @baseinfo = getAllLines(
        command => 'drweb-ctl baseinfo',
        %params
    );

    foreach my $line (@baseinfo) {
        if ($line =~ /^Virus database timestamp:\s+(\S+)/) {
            $av->{BASE_VERSION} = $1;
        }
    }

    my $expiration = getFirstMatch(
        command => 'drweb-ctl license',
        pattern => qr/expires (\d+-\w+-\d+)/,
        %params
    );
    if ($expiration && $expiration =~ /^(\d+)-(\w+)-(\d+)$/) {
        my $m = month($2);
        $av->{EXPIRATION} = sprintf("%d-%02d-%02d", $1, $m, $3) if $m;
    }


    return $av;
}

1;
