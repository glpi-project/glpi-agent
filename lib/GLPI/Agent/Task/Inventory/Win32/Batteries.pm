package GLPI::Agent::Task::Inventory::Win32::Batteries;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Batteries;
use GLPI::Agent::XML;

use constant    category    => "battery";

# Define some kind of priority so we can update batteries inventory
our $runAfterIfEnabled = [ qw(
    GLPI::Agent::Task::Inventory::Generic::Dmidecode::Battery
)];

sub isEnabled {
    return canRun('powercfg');
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
    $batteries->merge(_getBatteriesFromPowercfg(
        folder => $params{datadir},
        logger => $logger
    ));

    # Add back merged batteries into inventories
    foreach my $battery ($batteries->list()) {
        $inventory->addEntry(
            section => 'BATTERIES',
            entry   => $battery
        );
    }
}

sub _getBatteriesFromPowercfg {
    my (%params) = @_;

    my $folder = delete $params{folder} // '.';
    $folder =~ s{/}{\\}g;
    my $xmlfile = $folder.'\batteries.xml';

    # Just run command to generate xmlfile, we don't care about any output
    getAllLines(
        command => 'powercfg /batteryreport /xml /output "'.$xmlfile.'"',
        %params
    );

    $xmlfile =~ s{\\}{/}g;
    return unless has_file($xmlfile) || ($params{file} && has_file($params{file}));

    my $xml = GLPI::Agent::XML->new(
        force_array => [ qw(Battery) ],
        file        => $xmlfile,
        %params
    );

    # Cleanup generated xml file after it has been loaded
    unlink $xmlfile;

    my $powercfg = $xml->dump_as_hash()
        or return;

    # Check validity
    return unless ref($powercfg) eq 'HASH' && ref($powercfg->{BatteryReport}) eq 'HASH'
        && ref($powercfg->{BatteryReport}->{Batteries}) eq 'HASH';

    return unless exists($powercfg->{BatteryReport}->{Batteries}->{Battery})
        && ref($powercfg->{BatteryReport}->{Batteries}->{Battery}) eq 'ARRAY';

    my @batteries;
    foreach my $data (@{$powercfg->{BatteryReport}->{Batteries}->{Battery}}) {
        my $battery = {
            NAME            => $data->{'Id'},
            MANUFACTURER    => $data->{'Manufacturer'},
            CHEMISTRY       => $data->{'Chemistry'},
            SERIAL          => sanitizeBatterySerial($data->{'SerialNumber'}),
        };

        if ($data->{'DesignCapacity'}) {
            my $capacity = getCanonicalCapacity($data->{'DesignCapacity'}.' mWh');
            $battery->{CAPACITY} = $capacity
                if $capacity;
        }

        if ($data->{'FullChargeCapacity'}) {
            my $real_capacity = getCanonicalCapacity($data->{'FullChargeCapacity'}.' mWh');
            $battery->{REAL_CAPACITY} = $real_capacity
                if defined($real_capacity) && length($real_capacity);
        }

        push @batteries, $battery;
    }

    return @batteries;
}

1;
