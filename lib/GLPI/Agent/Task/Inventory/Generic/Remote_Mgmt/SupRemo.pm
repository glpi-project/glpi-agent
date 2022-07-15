package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::SupRemo;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    if (OSNAME eq 'MSWin32') {

        GLPI::Agent::Tools::Win32->use();

        # Depending on the installation the supremo key can be in two place in X64 OS

        my $key = getRegistryKey(
            path => "HKEY_LOCAL_MACHINE/SOFTWARE/Supremo",
            # Important for remote inventory optimization
            required    => [ qw/ClientID/ ],
            maxdepth    => 1,
            logger => $params{logger}
        );
        if (!$key && is64bit()) {
            $key = getRegistryKey(
                path => "HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Supremo",
                # Important for remote inventory optimization
                required    => [ qw/ClientID/ ],
                maxdepth    => 1,
                logger => $params{logger}
            );
        }

        return $key && (keys %$key);
    }

    return canRun('supremo');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $supRemoID = OSNAME eq 'MSWin32' ?
        _getID_MSWin32(logger  => $logger) : _getID_supremo_info(logger  => $logger);
    if (defined($supRemoID)) {
        $logger->debug('Found SupRemoID : ' . $supRemoID) if ($logger);

        $inventory->addEntry(
            section => 'REMOTE_MGMT',
            entry   => {
                ID   => $supRemoID,
                TYPE => 'supremo'
            }
        );
    } else {
        $logger->debug('SupRemoID not found') if ($logger);
    }
}


sub _getID_MSWin32 {

    GLPI::Agent::Tools::Win32->use();

    my $clientid = getRegistryValue(
        path => "HKEY_LOCAL_MACHINE/SOFTWARE/Supremo/ClientID",
    );
    if (!$clientid && is64bit()) {
        $clientid = getRegistryValue(
            path => "HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Supremo/ClientID",
        );
    }

    unless ($clientid) {
        my $supremover_reg = getRegistryKey(
            path => "HKEY_LOCAL_MACHINE/SOFTWARE/Supremo",
            # Important for remote inventory optimization
            required    => [ qw/ClientID/ ],
            maxdepth    => 2,
        );
        if(!$supremover_reg && is64bit()){
            $supremover_reg = getRegistryKey(
                path => "HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Supremo",
                # Important for remote inventory optimization
                required    => [ qw/ClientID/ ],
                maxdepth    => 2,
            );
        }

        return unless $supremover_reg;

        # Look for subkey beginning with Version
        foreach my $key (keys(%{$supremover_reg})) {
            next unless $key =~ /^Version\d+\//;
            $clientid = $supremover_reg->{$key}->{"/ClientID"};
            last if (defined($clientid));
        }
    }

    return unless $clientid;

    return sprintf("%09d",hex2dec($clientid));
}

sub _getID_supremo_info {
    my (%params) = @_;

    return getFirstMatch(
        command => "supremo --info",
        pattern => qr/SupRemo ID:(?:\033\[0m|\s)*(\d+)\s+/,
        %params
    );
}

1;
