package GLPI::Agent::Task::Inventory::Generic::Batteries::Acpiconf;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Batteries;

# Define some kind of priority so we can update batteries inventory
our $runAfterIfEnabled = [ qw(
    GLPI::Agent::Task::Inventory::Generic::Dmidecode::Battery
    GLPI::Agent::Task::Inventory::Generic::Batteries::Upower
)];

sub isEnabled {
    return canRun('acpiconf');
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
    $batteries->merge(_getBatteriesFromAcpiconf(logger => $logger));

    # Add back merged batteries into inventories
    foreach my $battery ($batteries->list()) {
        $inventory->addEntry(
            section => 'BATTERIES',
            entry   => $battery
        );
    }
}

sub _getBatteriesFromAcpiconf {
    my (%params) = @_;

    my @batteries = ();
    my $index = 0;

    while (
        my $battery = _getBatteryFromAcpiconf(
            index   => $index,
            %params
        )
    ) {
        push @batteries, $battery;
        $index ++;
    }

    return @batteries;
}

sub _getBatteryFromAcpiconf {
    my (%params) = @_;

    $params{command} = 'acpiconf -i ' . $params{index}
        if defined($params{index});

    my @lines = getAllLines(%params);

    return unless @lines;

    my $data = {};
    foreach my $line (@lines) {
        if ($line =~ /^(.*):\s*(\S+(?:\s+\S+)*)$/) {
            $data->{$1} = $2;
        }
    }

    my $battery = {
        NAME            => $data->{'Model number'},
        CHEMISTRY       => $data->{'Type'},
        SERIAL          => sanitizeBatterySerial($data->{'Serial number'}),
    };

    my $voltage  = getCanonicalVoltage($data->{'Design voltage'});
    $battery->{VOLTAGE} = $voltage
        if $voltage;

    my $capacity = getCanonicalCapacity($data->{'Design capacity'}, $voltage);
    $battery->{CAPACITY} = $capacity
        if $capacity;

    my $realCapacity = getCanonicalCapacity($data->{'Last full capacity'}, $voltage);
    $battery->{REAL_CAPACITY} = $realCapacity
        if $realCapacity;

    return $battery;
}

1;
