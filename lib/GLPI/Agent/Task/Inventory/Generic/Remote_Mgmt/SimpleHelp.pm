package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::SimpleHelp;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

use constant sgalive_win32 => 'C:\ProgramData\JWrapper-Remote Access\JWAppsSharedConfig\sgalive';
use constant sgalive_macos => '/Library/Application Support/JWrapper-Remote Access/JWAppsSharedConfig/sgalive';
use constant sgalive_linux => '/opt/JWrapper-Remote Access/JWAppsSharedConfig/sgalive';

my $sgalive = OSNAME eq 'MSWin32' ? sgalive_win32 :
              OSNAME eq 'darwin'  ? sgalive_macos : sgalive_linux;

sub isEnabled {
    return has_file($sgalive);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $SimpleHelpID = getFirstMatch(
        file    => $sgalive,
        logger  => $logger,
        pattern => qr/^ID=SG(?:_SG)?_(-?\d+)$/
    );

    if (defined($SimpleHelpID)) {
        $SimpleHelpID = "SG_".$SimpleHelpID;
        $logger->debug('Found SimpleHelp ID : ' . $SimpleHelpID) if $logger;

        $inventory->addEntry(
            section => 'REMOTE_MGMT',
            entry   => {
                ID   => $SimpleHelpID,
                TYPE => 'simplehelp'
            }
        );
    } else {
        $logger->debug('SimpleHelp ID not found in '.$sgalive) if $logger;
    }
}

1;
