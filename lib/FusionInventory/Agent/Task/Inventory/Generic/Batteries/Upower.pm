package FusionInventory::Agent::Task::Inventory::Generic::Batteries::Upower;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Batteries;

# Run after virtualization to decide if found component is virtual
our $runAfterIfEnabled = [ qw(
    FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Battery
)];

sub isEnabled {
    my (%params) = @_;
    return canRun('upower');
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
    $batteries->merge(_getBatteriesFromUpower(logger => $logger));

    # Add back merged batteries into inventories
    foreach my $battery ($batteries->list()) {
        $inventory->addEntry(
            section => 'BATTERIES',
            entry   => $battery
        );
    }
}

sub _getBatteriesFromUpower {
    my (%params) = @_;

    my @batteriesName = _getBatteriesNameFromUpower(%params);

    return unless @batteriesName;

    my @batteries = ();
    foreach my $battName (@batteriesName) {
        my $battery = _getBatteryFromUpower(
            name    => $battName,
            %params
        );
        push @batteries, $battery
            if $battery;
    }

    return @batteries;
}

sub _getBatteriesNameFromUpower {
    my (%params) = @_;

    my @lines = getAllLines(
        command => 'upower --enumerate',
        %params
    );

    my @battName;
    for my $line (@lines) {
        if ($line =~ /^(.*\/battery_\S+)$/) {
            push @battName, $1;
        }
    }

    return @battName;
}

sub _getBatteryFromUpower {
    my (%params) = @_;

    $params{command} = 'upower -i ' . $params{name}
        if defined($params{name});

    my @lines = getAllLines(%params);

    return unless @lines;

    my $data = {};
    foreach my $line (@lines) {
        if ($line =~ /^\s*(\S+):\s*(\S+(?:\s+\S+)*)$/) {
            $data->{$1} = $2;
        }
    }

    my $battery = {
        NAME            => $data->{'model'},
        CHEMISTRY       => $data->{'technology'},
        SERIAL          => sanitizeBatterySerial($data->{'serial'}),
    };

    my $manufacturer = $data->{'vendor'} || $data->{'manufacturer'};
    $battery->{MANUFACTURER} = getCanonicalManufacturer($manufacturer)
        if $manufacturer;

    my $voltage  = getCanonicalVoltage($data->{'voltage'});
    $battery->{VOLTAGE} = $voltage
        if $voltage;

    my $capacity = getCanonicalCapacity($data->{'energy-full-design'}, $voltage);
    $battery->{CAPACITY} = $capacity
        if $capacity;

    return $battery;
}

1;
