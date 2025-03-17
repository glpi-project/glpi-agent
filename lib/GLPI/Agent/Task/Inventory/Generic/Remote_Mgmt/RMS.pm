package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::RMS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return 0 unless OSNAME eq 'MSWin32';

    GLPI::Agent::Tools::Win32->use();

    my $key = getRegistryKey(
        path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Usoris/Remote Utilities Host/Host/Parameters',
        # Important for remote inventory optimization
        required    => [ qw/InternetId/ ],
        maxdepth    => 1,
    );

    return defined($key) && keys(%{$key}) ? 1 : 0;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $InternetID = _getID(logger  => $logger);

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

    GLPI::Agent::Tools::Win32->use();
    GLPI::Agent::XML->use();

    my $internetid = getRegistryValue(
        path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Usoris/Remote Utilities Host/Host/Parameters/InternetId',
        %params
    );

    $internetid = hex2dec($internetid);

    my $tree = GLPI::Agent::XML->new(string => $internetid)->dump_as_hash();

    return unless defined($tree) && defined($tree->{rms_internet_id_settings});

    return $tree->{rms_internet_id_settings}->{internet_id};
}

1;
