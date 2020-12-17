package FusionInventory::Agent::Task::Inventory::Win32::Storages::HP;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools::Win32;
use FusionInventory::Agent::Tools::Storages::HP;

sub isEnabled {
    return _getHpacuacliFromWinRegistry();
}

sub doInventory {
    my (%params) = @_;
    my $logger   = $params{logger};

    HpInventory(
        path => _getHpacuacliFromWinRegistry($logger),
        %params
    );
}

sub _getHpacuacliFromWinRegistry {

    my $uninstallValues = getRegistryKey(
        path => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/HP ACUCLI"
    );
    return unless $uninstallValues;

    my $uninstallString = $uninstallValues->{'/UninstallString'};
    return unless $uninstallString;

    return unless $uninstallString =~ /(.*\\)hpuninst\.exe/;
    my $hpacuacliPath = $1 . 'bin\\hpacucli.exe';
    return unless has_file($hpacuacliPath);

    return $hpacuacliPath;
}

1;
