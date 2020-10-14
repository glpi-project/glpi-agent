package FusionInventory::Agent::Task::Inventory::Generic::Ipmi::Fru::Controllers;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::IpmiFru;

my $CONTROLLERS = qr/^(?:
    BP             |
    PERC           |
    NDC            |
    Ethernet Adptr |
    SAS Ctlr
)\d*\s+/x;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{controller};
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $fru = getIpmiFru(%params)
        or return;

    my @fru_keys = grep { $_ =~ $CONTROLLERS } keys %$fru
        or return;

    my @fields = keys %{$inventory->getFields()->{CONTROLLERS}};
    for my $descr (@fru_keys) {
        my $ctrl = parseFru($fru->{$descr}, \@fields);
        next unless keys %$ctrl;

        $ctrl->{TYPE} = $1 if $descr =~ /^([\w\s]+[[:alpha:]])/;

        $inventory->addEntry(
            section => 'CONTROLLERS',
            entry   => $ctrl
        );
    }
}

1;
