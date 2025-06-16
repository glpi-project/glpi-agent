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
    my $logger = $params{logger};

    my $av = {
        NAME     => 'Dr.Web',
        COMPANY  => 'Doctor Web',  
        ENABLED  => 0,               
        UPTODATE => 0,               
    };

    my $version_output = getFirstLine(
        command => 'LANG=C drweb-ctl --version',
        %params
    );

    if ($version_output && $version_output =~ /drweb-ctl\s+([\d.]+)/) {
        $av->{VERSION} = $1;
    }

    my $service_status = getFirstLine(
        command => 'LANG=C systemctl is-active drweb-configd.service',
        %params
    );
    $av->{ENABLED} = $service_status && $service_status eq 'active' ? 1 : 0;

    my @baseinfo = getAllLines(
        command => 'LANG=C drweb-ctl baseinfo',
        %params
    );

    foreach my $line (@baseinfo) {
        if ($line =~ /Virus database timestamp:\s+(.+)/) {
            $av->{BASE_VERSION} = $1;
            last;
        }
    }

    return $av;
}

1;