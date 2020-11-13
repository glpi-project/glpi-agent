package FusionInventory::Agent::Task::Inventory::MacOS::Psu;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::MacOS;
use FusionInventory::Agent::Tools::PowerSupplies;

our $runAfterIfEnabled = [ qw(
    FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Psu
)];

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{psu};
    return canRun('/usr/sbin/system_profiler');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $charger = _getCharger(logger => $logger)
        or return;

    # Empty current POWERSUPPLIES section into a new psu list
    my $psulist = Inventory::PowerSupplies->new( logger => $logger );
    my $section = $inventory->getSection('POWERSUPPLIES') || [];
    while (@{$section}) {
        my $powersupply = shift @{$section};
        $psulist->add($powersupply);
    }

    $psulist->merge($charger);

    # Add back merged powersupplies into inventory
    foreach my $psu ($psulist->list()) {
        $inventory->addEntry(
            section => 'POWERSUPPLIES',
            entry   => $psu
        );
    }
}

sub _getCharger {
    my (%params) = @_;

    my $infos = FusionInventory::Agent::Tools::MacOS::getSystemProfilerInfos(
        type    => 'SPPowerDataType',
        format  => 'text',
        %params
    );

    return unless $infos->{Power};

    my $infoPower = $infos->{Power}->{'AC Charger Information'}
        or return;

    my $charger = {
        SERIALNUMBER    => $infoPower->{'Serial Number'},
        NAME            => $infoPower->{'Name'},
        MANUFACTURER    => $infoPower->{'Manufacturer'},
        STATUS          => $infoPower->{'Charging'} && $infoPower->{'Charging'} eq "Yes" ? "Charging" : "Not charging",
        PLUGGED         => $infoPower->{'Connected'} // "No",
        POWER_MAX       => $infoPower->{'Wattage (W)'},
    };

    return $charger;
}

1;
