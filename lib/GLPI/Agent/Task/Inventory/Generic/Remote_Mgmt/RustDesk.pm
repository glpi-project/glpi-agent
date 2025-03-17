package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::RustDesk;

# Based on the work done by Ilya published on no more existing https://fusioninventory.userecho.com site

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub _get_rustdesk_config {
    return OSNAME eq 'MSWin32' ?
        'C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml' :
        '/root/.config/rustdesk/RustDesk.toml';
}

sub isEnabled {
    return has_file(_get_rustdesk_config());
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $conf = _get_rustdesk_config();
    my $RustDeskID = getFirstMatch(
        file    => $conf,
        logger  => $logger,
        pattern => qr/^id\s*=\s*'(.*)'$/
    );

    # Add support for --get-id parameter available since RustDesk 1.2 as id becomes empty in conf
    # Only works starting with RustDesk v1.2.2
    unless (defined($RustDeskID) && length($RustDeskID)) {
        my $command = 'rustdesk';
        if(OSNAME eq 'MSWin32'){
            GLPI::Agent::Tools::Win32->require();
            my $installLocation = GLPI::Agent::Tools::Win32::getRegistryValue(
                path   => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/RustDesk/InstallLocation",
                logger => $logger
            );
            $command = (empty($installLocation) ? 'C:\Program Files\RustDesk' : $installLocation) . '\rustdesk.exe';
        }
        if (canRun($command)) {
            $command = '"'.$command.'"' if OSNAME eq 'MSWin32';
            my $required = 1;
            my $version = getFirstLine(
                command => $command." --version",
                logger  => $logger
            );
            if ($version && $version =~ /^(\d+)\.(\d+)\.(\d+)/) {
                $required = int($1) > 1 || (int($1) == 1 && int($2) > 2) || (int($1) == 1 && int($2) == 2 && int($3) >= 2) ? 0 : 1;
            }
            if ($required) {
                $logger->debug("Can't get RustDesk ID, at least RustDesk v1.2.2 is required") if $logger;
                return;
            }
            $RustDeskID = getFirstMatch(
                command => $command." --get-id",
                logger  => $logger,
                pattern => qr/^(\d+)$/
            );
            unless ($RustDeskID) {
                $logger->debug("Can't get RustDesk ID, RustDesk is probably not running") if $logger;
                return;
            }
        }
    }

    if (defined($RustDeskID)) {
        $logger->debug('Found RustDesk ID : ' . $RustDeskID) if $logger;

        $inventory->addEntry(
            section => 'REMOTE_MGMT',
            entry   => {
                ID   => $RustDeskID,
                TYPE => 'rustdesk'
            }
        );
    } else {
        $logger->debug('RustDesk ID not found in '.$conf) if $logger;
    }
}

1;
