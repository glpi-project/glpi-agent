package FusionInventory::Agent::Task::Inventory::Generic::Ipmi::Fru::Psu;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::IpmiFru;
use FusionInventory::Agent::Tools::PowerSupplies;

# Run after virtualization to decide if found component is virtual
our $runAfterIfEnabled = [ qw(
    FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Psu
)];

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{psu};
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
        push @fru, parseFru($fru->{$descr}, [keys %$fields]);
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
