package GLPI::Agent::Task::Inventory::Linux::AntiVirus::EEA;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use POSIX qw(mktime);

use GLPI::Agent::Tools;

use constant upd => '/opt/eset/eea/bin/upd';
use constant lic => '/opt/eset/eea/sbin/lic';

sub isEnabled {
    return canRun(upd) && canRun(lic);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getEEAInfo(logger => $logger);
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

sub _getEEAInfo {
    my (%params) = @_;

    my $av = {
        NAME     => 'ESET Endpoint Antivirus',
        COMPANY  => 'ESET',
        ENABLED  => 0,
        UPTODATE => 0,
    };

    my $version = getFirstMatch(
        file    => $params{upd_version}, # Only used by tests
        pattern => qr/\(eea\)\s*([0-9.]+)/,
        command => upd . " -version",
        %params
    );
    $av->{VERSION} = $version if $version;

    my $service_status = getFirstLine(
        file    => $params{svc_status}, # Only used by tests
        command => 'systemctl is-active eea.service',
        %params
    );
    $av->{ENABLED} = $service_status && $service_status eq 'active' ? 1 : 0;

    my $expiration = getFirstMatch(
        file    => $params{lic_status}, # Only used by tests
        command => lic . ' --status',
        pattern => qr/License Validity:\s*(\d{4}-\d{2}-\d{2})/,
        %params
    );
    $av->{EXPIRATION} = $expiration if $expiration;

    my $base_version = getFirstMatch(
        file    => $params{upd_modules}, # Only used by tests
        command => upd . ' --list-modules',
        pattern => qr/EM002\s*(\d+\s*\(\d+\))\s*Detection engine$/,
        %params
    );
    $av->{BASE_VERSION} = $base_version if $base_version;

    # Since ESET does not allow us to check if we are up to date without forcing a module update
    # "upd -u" has no dry-run or check options.
    # Let's consider that we are up to date if the antivirus database is less than 2 days old.
    if ($base_version =~ /\((\d{4})(\d{2})(\d{2})\)$/) {
        my $two_days_ago = time - 2 * 24 * 60 * 60;
        if ($params{test_date}) { # Only used by tests
            $two_days_ago = mktime(split('-', $params{test_date})) - 2 * 24 * 60 * 60;
        }

        $av->{UPTODATE} = mktime(0, 0, 0, $3, $2-1, $1-1900) > $two_days_ago ? 1 : 0;
    }

    return $av;
}

1;
