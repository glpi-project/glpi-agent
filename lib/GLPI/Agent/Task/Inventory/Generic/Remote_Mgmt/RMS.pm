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
        # if (!$key && is64bit()) {
        #     $key = getRegistryKey(
        #         path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Usoris/Remote Utilities Host/Host/Parameters',
        #         # Important for remote inventory optimization
        #         required    => [ qw/InternetId/ ],
        #         maxdepth    => 1,
        #         logger => $params{logger}
        #     );
        # }

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
#     my (%params) = @_;
}

sub _getID_MSWin32 {

    GLPI::Agent::Tools::Win32->use();
    GLPI::Agent::XML->use();

    my $internetid = getRegistryValue(
        path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Usoris/Remote Utilities Host/Host/Parameters/InternetId',
    );

    $internetid = hex2dec($clientid);

    my $tree = GLPI::Agent::XML->new(string => $internetid)->dump_as_hash();

    return unless defined($tree) && defined($tree->{nodes_path_to_internet_id});

    return $tree->{nodes_path_to_internet_id}->{internet_id};
}

1;
