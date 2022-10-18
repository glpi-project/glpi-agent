package GLPI::Agent::Task::Inventory::Generic::Ipmi::Fru::Psu;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::IpmiFru;
use GLPI::Agent::Tools::PowerSupplies;

use constant    category    => "psu";

# Define a priority so we can update powersupplies inventory
our $runAfterIfEnabled = [ qw(
    GLPI::Agent::Task::Inventory::Generic::Dmidecode::Psu
)];

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $fru = getIpmiFru(%params)
        or return;

    my @fru_keys = grep { /^(PS|Pwr Supply )\d+/ } keys(%{$fru})
        or return;

    # Empty current POWERSUPPLIES section into a new psu list
    my $psulist = Inventory::PowerSupplies->new( logger => $logger );
    my $section = $inventory->getSection('POWERSUPPLIES') || [];
    while (@{$section}) {
        my $powersupply = shift @{$section};
        $psulist->add($powersupply);
    }

    # Merge powersupplies reported by ipmitool
    my @fru = ();
    my $fields = $inventory->getFields()->{'POWERSUPPLIES'};

    # omit MODEL field as it's duplicate of PARTNUM field
    delete $fields->{'MODEL'};

    foreach my $descr (sort @fru_keys) {
        push @fru, parseFru($fru->{$descr}, $fields);
    }
    $psulist->merge(@fru);

    # Add back merged powersupplies into inventory
    foreach my $psu ($psulist->list()) {
        $inventory->addEntry(
            section => 'POWERSUPPLIES',
            entry   => $psu
        );
    }
}

1;
