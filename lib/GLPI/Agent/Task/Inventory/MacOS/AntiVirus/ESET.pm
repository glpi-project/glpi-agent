package GLPI::Agent::Task::Inventory::MacOS::AntiVirus::ESET;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use POSIX qw(mktime);
use Cpanel::JSON::XS;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;
use GLPI::Agent::XML;

my @eset_app_paths = (
    '/Applications/ESET Endpoint Security.app/Contents/MacOS',
    '/Applications/ESET Endpoint Antivirus.app/Contents/MacOS',
);

sub _getESETBasePath {
    foreach my $path (@eset_app_paths) {
        return $path if canRun("$path/upd");
    }
    return;
}

sub isEnabled {
    return _getESETBasePath() ? 1 : 0;
}

sub doInventory {
    my (%params) = @_;
    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getESETInfo(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME}".($antivirus->{VERSION}? " v$antivirus->{VERSION}":""))
            if $logger;
    }
}

sub _getESETInfo {
    my (%params) = @_;
    my $basepath = $params{basepath} || _getESETBasePath();
    return unless $basepath || $params{upd_version};

    my $antivirus = {
        COMPANY  => 'ESET',
        ENABLED  => 0,
        UPTODATE => 0,
    };

    # Get product version from `upd -version`
    # Output: "/Applications/.../upd (ees_mac) 9.1.3100.0" or with test file
    my $version = getFirstMatch(
        file    => $params{upd_version}, # For unit tests
        command => $basepath ? [ "$basepath/upd", "-version" ] : undef,
        pattern => qr/\((?:ee[a-z_]+)\)\s*([0-9.]+)/,
        %params
    );
    $antivirus->{VERSION} = $version if $version;

    # Get product name and license info from `lic --status`
    if ($params{lic_status}) {
        # For unit tests
        $params{file} = $params{lic_status};
    } else {
        $params{command} = [ "$basepath/lic", "-status" ];
    }
    my @lic_lines = getAllLines(%params);
    foreach my $line (@lic_lines) {
        if ($line =~ /^Product name:\s*(.+)/) {
            $antivirus->{NAME} //= $1;
        } elsif ($line =~ /^License Validity:\s*(\d{4}-\d{2}-\d{2})/) {
            $antivirus->{EXPIRATION} //= $1;
        }
    }

    unless ($antivirus->{NAME}) {
        if ($basepath && $basepath =~ /\/([^\/]+)\.app\//) {
            $antivirus->{NAME} = $1;
        }
    }

    # Get detection engine version from `upd --list-modules`
    if ($params{upd_modules}) {
        # For unit tests
        $params{file} = $params{upd_modules};
    } else {
        $params{command} = [ "$basepath/upd", "--list-modules" ];
    }
    my $base_version = getFirstMatch(
        pattern => qr/EM002\s*(\d+\s*\(\d+\))\s*Detection engine$/,
        %params
    );
    $antivirus->{BASE_VERSION} = $base_version if $base_version;

    # Parse com.eset.protection plist to find daemon command (e.g. startd) using built-in XML parser
    my $daemon_plist = $params{daemon_plist} || '/Library/LaunchDaemons/com.eset.protection.plist';
    my $start_cmd;
    if (has_file($daemon_plist)) {
        GLPI::Agent::XML->require();
        my $xml = eval { GLPI::Agent::XML->new(file => $daemon_plist, is_plist => 1)->dump_as_hash() };
        if (!$@ && $xml && $xml->{plist}) {
            my $dict = ref($xml->{plist}) eq 'ARRAY' ? $xml->{plist}->[0] : (ref($xml->{plist}) eq 'HASH' ? $xml->{plist} : undef);
            if ($dict && ref($dict) eq 'HASH') {
                if (ref($dict->{ProgramArguments}) eq 'ARRAY') {
                    $start_cmd = $dict->{ProgramArguments}->[0];
                } elsif (!ref($dict->{ProgramArguments})) {
                    $start_cmd = $dict->{ProgramArguments};
                }
            }
        }
    }
    $start_cmd ||= "$basepath/startd" if $basepath;

    my $startd_running = 0;
    if ($start_cmd) {
        my $filter = quotemeta($start_cmd);
        # For unit tests
        $params{file} = $params{ps_status}
            if $params{ps_status};
        my ($ps) = getProcesses(
            filter => qr/$filter/i,
            %params
        );
        $startd_running = $ps ? 1 : 0;
    }

    # Check if real-time protection is enabled in settings.json
    my $rtp_enabled = 0;
    my $settings_file = $params{settings_file} || '/Library/Application Support/ESET/Security/var/confd/settings.json';
    if (has_file($settings_file)) {
        $params{file} = $settings_file;
        my $content = getAllLines(%params);
        if ($content) {
            eval {
                my $json = decode_json($content);
                my $rtfs_enabled = $json->{State}->{ProtectionStatus}->{RTFSEnabled}->{Active}->{ce_val};
                $rtp_enabled = 1
                    if $rtfs_enabled && $rtfs_enabled == 1;
            };
        }
    }

    $antivirus->{ENABLED} = ($startd_running && $rtp_enabled) ? 1 : 0;

    # Up-to-date heuristic (same as Linux EEA)
    if ($base_version && $base_version =~ /\((\d{4})(\d{2})(\d{2})\)$/) {
        my $two_days_ago = time - 2 * 24 * 60 * 60;
        if ($params{test_date}) { # For unit tests
            $two_days_ago = mktime(split('-', $params{test_date})) - 2 * 24 * 60 * 60;
        }
        $antivirus->{UPTODATE} = mktime(0, 0, 0, $3, $2-1, $1-1900) > $two_days_ago ? 1 : 0;
    }

    return $antivirus;
}

1;
