package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::RMS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    if (OSNAME eq 'MSWin32') {

        GLPI::Agent::Tools::Win32->use();

        my $key = getRegistryKey(
            path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Usoris/Remote Utilities Host/Host/Parameters',
            # Important for remote inventory optimization
            required    => [ qw/InternetId/ ],
            maxdepth    => 1,
            logger => $params{logger}
        );
        if (!$key && is64bit()) {
            $key = getRegistryKey(
                path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Usoris/Remote Utilities Host/Host/Parameters',
                # Important for remote inventory optimization
                required    => [ qw/InternetId/ ],
                maxdepth    => 1,
                logger => $params{logger}
            );
        }

        return 1;
    }

    return canRun('rms');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $InternetID = OSNAME eq 'MSWin32' ? _getID_MSWin32(logger  => $logger) : _getID(logger  => $logger);
    );
    if (defined($InternetID)) {
        $logger->debug('Found InternetID : ' . $InternetID) if ($logger);

        $inventory->addEntry(
            section => 'REMOTE_MGMT',
            entry   => {
                ID   => $InternetID,
                TYPE => 'rms'
            }
        );
    } else {
        $logger->debug('InternetID not found') if ($logger);
    }
}

sub _getID {
    my (%params) = @_;
    my $osname = delete $params{osname} // '';
    return _getID_MSWin32() if $osname eq "MSWin32";
}

sub _getID_MSWin32 {

    GLPI::Agent::Tools::Win32->use();

    my $clientid = getRegistryValue(
        path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Usoris/Remote Utilities Host/Host/Parameters/InternetId',
    );

    $clientid = hex2dec($clientid);

    $clientid = substr($clientid, 0, index($clientid, '</internet_id'));
    $clientid = substr($clientid, index($clientid, '<internet_id>')+13);

    return $clientid;

}

1;
