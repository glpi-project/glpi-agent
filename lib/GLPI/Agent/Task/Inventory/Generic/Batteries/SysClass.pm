package GLPI::Agent::Task::Inventory::Generic::Batteries::SysClass;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Batteries;

# Define some kind of priority so we can update batteries inventory
our $runAfterIfEnabled = [ qw(
    GLPI::Agent::Task::Inventory::Generic::Dmidecode::Battery
    GLPI::Agent::Task::Inventory::Generic::Batteries::Acpiconf
    GLPI::Agent::Task::Inventory::Generic::Batteries::Upower
)];

sub isEnabled {
    return Glob("/sys/class/power_supply/*/capacity");
}

sub doInventory {
    my (%params) = @_;

    my $logger    = $params{logger};
    my $inventory = $params{inventory};

    my $batteries = Inventory::Batteries->new( logger => $logger );
    my $section   = $inventory->getSection('BATTERIES') || [];

    # Empty current BATTERIES section into a new batteries list
    while (@{$section}) {
        my $battery = shift @{$section};
        $batteries->add($battery);
    }

    # Merge batteries reported by upower
    $batteries->merge(_getBatteriesFromSysClass(logger => $logger));

    # Add back merged batteries into inventories
    foreach my $battery ($batteries->list()) {
        $inventory->addEntry(
            section => 'BATTERIES',
            entry   => $battery
        );
    }
}

sub _getBatteriesFromSysClass {
    my (%params) = @_;

    my @batteries = ();
    foreach my $psu (Glob("/sys/class/power_supply/*")) {
        my $type = getFirstLine(file => "$psu/type")
            or next;
        my $present = getFirstLine(file => "$psu/present")
            or next;
        next unless $type eq "Battery" && has_file("$psu/capacity");
        my $battery = _getBatteryFromSysClass(
            psu     => $psu,
            %params
        );
        push @batteries, $battery
            if $battery;
    }

    return @batteries;
}

sub _getBatteryFromSysClass {
    my (%params) = @_;

    my $battery = {
        NAME            => getFirstLine(file => "$params{psu}/model_name"),
        CHEMISTRY       => getFirstLine(file => "$params{psu}/technology"),
        SERIAL          => sanitizeBatterySerial(getFirstLine(file => "$params{psu}/serial_number")),
    };

    my $manufacturer = getFirstLine(file => "$params{psu}/manufacturer");
    $battery->{MANUFACTURER} = getCanonicalManufacturer($manufacturer)
        if $manufacturer;

    # Voltage is provided in µV
    my $voltage  = getFirstLine(file => "$params{psu}/voltage_min_design");
    $battery->{VOLTAGE} = int($voltage/1000)
        if $voltage;

    # Energy full design is provided in µWh
    my $capacity = getFirstLine(file => "$params{psu}/energy_full_design");
    $battery->{CAPACITY} = int($capacity/1000)
        if $capacity;

    # Charge full design is provided in µAh
    unless ($capacity) {
        my $charge = getFirstLine(file => "$params{psu}/charge_full_design");
        $capacity = getCanonicalCapacity(int($charge/1000)." mAh", $battery->{VOLTAGE})
            if $charge && $battery->{VOLTAGE};
        $battery->{CAPACITY} = $capacity
            if $capacity;
    }

    # Real ernergy is provided in µWh
    my $realCapacity = getFirstLine(file => "$params{psu}/energy_full");
    $battery->{REAL_CAPACITY} = int($realCapacity/1000)
        if $realCapacity;


    # Real charge is provided in µAh
    unless ($realCapacity) {
        my $realCharge = getFirstLine(file => "$params{psu}/charge_full");
        $realCharge = getCanonicalCapacity(int($realCharge/1000)." mAh", $battery->{VOLTAGE})
            if $realCharge && $battery->{VOLTAGE};
        $battery->{REAL_CAPACITY} = $realCharge
            if $realCharge;
    }

    return $battery;
}

1;
