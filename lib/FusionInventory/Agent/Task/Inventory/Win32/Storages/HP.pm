package FusionInventory::Agent::Task::Inventory::Win32::Storages::HP;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

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

    my $Registry;
    Win32::TieRegistry->require();
    Win32::TieRegistry->import(
        Delimiter   => '/',
        ArrayValues => 0,
        TiedRef     => \$Registry,
    );

    my $machKey = $Registry->Open('LMachine', {
        Access => Win32::TieRegistry::KEY_READ(),
    }) or die "Can't open HKEY_LOCAL_MACHINE key: $EXTENDED_OS_ERROR";

    my $uninstallValues =
        $machKey->{'SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/HP ACUCLI'};
    return unless $uninstallValues;

    my $uninstallString = $uninstallValues->{'/UninstallString'};
    return unless $uninstallString;

    return unless $uninstallString =~ /(.*\\)hpuninst\.exe/;
    my $hpacuacliPath = $1 . 'bin\\hpacucli.exe';
    return unless -f $hpacuacliPath;

    return $hpacuacliPath;
}

1;
