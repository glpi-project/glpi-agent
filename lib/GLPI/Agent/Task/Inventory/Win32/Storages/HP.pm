package GLPI::Agent::Task::Inventory::Win32::Storages::HP;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools::Win32;
use GLPI::Agent::Tools::Storages::HP;

sub isEnabled {
    return _getHpacuacliFromWinRegistry();
}

sub doInventory {
    my (%params) = @_;

    my $hpacucli_path = _getHpacuacliFromWinRegistry()
        or return;

    HpInventory(
        path    => $hpacucli_path,
        %params
    );
}

sub _getHpacuacliFromWinRegistry {

    my $uninstallString = getRegistryValue(
        path => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/HP ACUCLI/UninstallString",
    );
    return unless $uninstallString && $uninstallString =~ /(.*\\)hpuninst\.exe/;
    my $hpacuacliPath = $1 . 'bin\\hpacucli.exe';
    return unless has_file($hpacuacliPath);

    return $hpacuacliPath;
}

1;
