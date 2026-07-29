package GLPI::Agent::Task::Inventory::Linux::AntiVirus::ClamAV;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

my $clamscan_bin  = '/usr/bin/clamscan';
my $systemctl_bin = '/usr/bin/systemctl';

sub isEnabled {
    return canRun($clamscan_bin);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getClamAVInfo(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME}" . ($antivirus->{VERSION} ? " v$antivirus->{VERSION}" : ""))
            if $logger;
    }
}

sub _getClamAVInfo {
    my (%params) = @_;

    my $logger = $params{logger};

    # For tests, the following parameters can be set in %params:
    # - clamscan_version:    output of /usr/bin/clamscan --version
    # - clamscan_is_active:  output of /usr/bin/systemctl is-active clamav-daemon
    # - freshclam_is_active: output of /usr/bin/systemctl is-active clamav-freshclam
    # - freshclam_status:    output of /usr/bin/systemctl status clamav-freshclam.service
    # - db_file:             file for testing database time

    # Get version from clamscan
    my ($version, $base_version) = getFirstMatch(
        command => $params{clamscan_version} ? "" : [ $clamscan_bin, '--version' ],
        pattern => qr/ClamAV\s+([^\/]+)\/(\d+)/,
        logger  => $logger,
        string  => $params{clamscan_version},
    );

    # Get actual status
    my $is_enabled = 0;
    my $canrun_systemctl = defined($params{clamscan_is_active}) || canRun($systemctl_bin);
    if ($canrun_systemctl) {
        my $status = getFirstLine(
            command => $params{clamscan_is_active} ? "" : [ $systemctl_bin, 'is-active', 'clamav-daemon' ],
            logger  => $logger,
            string  => $params{clamscan_is_active},
        );
        $is_enabled = 1 unless empty($status) || $status !~ /^active/;
    }

    # check updates
    my $is_uptodate = 0;

    if ($canrun_systemctl) {
        my $fresh_status = getFirstLine(
            command => $params{freshclam_is_active} ? "" : [ $systemctl_bin, 'is-active', 'clamav-freshclam' ],
            logger  => $logger,
            string  => $params{freshclam_is_active},
        );

        if ($fresh_status && $fresh_status =~ /^active/) {
            $is_uptodate = 1;
        } else {
            my $detailed_status = getFirstLine(
                command => $params{freshclam_status} ? "" : [ $systemctl_bin, 'status', 'clamav-freshclam.service' ],
                logger  => $logger,
                string  => $params{freshclam_status},
            );
            $is_uptodate = 1
                unless empty($detailed_status) || $detailed_status !~ /database is up-to-date/i;
        }
    }

    unless ($is_uptodate) {
        my $db_cvd = '/var/lib/clamav/daily.cvd';
        my $db_cld = '/var/lib/clamav/daily.cld';
        my $db_file = $params{db_file} ? $params{db_file} :
            has_file($db_cvd) ? $db_cvd :
            has_file($db_cld) ? $db_cld : '';

        if ($db_file) {
            my $stat = FileStat($db_file);
            my $days_old = int((time - $stat->mtime)/86400);
            $is_uptodate = 1 unless $days_old > 3;
        }
    }

    return {
        NAME         => 'ClamAV',
        COMPANY      => 'Cisco Systems / Open Source',
        VERSION      => $version || '',
        BASE_VERSION => $base_version || '',
        ENABLED      => $is_enabled,
        UPTODATE     => $is_uptodate,
    };
}

1;
