package GLPI::Agent::Task::Inventory::Generic::Softwares::Gentoo;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('equery');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $command = _equeryNeedsWildcard() ?
        "equery list -i '*'" : "equery list -i";

    my $packages = _getPackagesList(
        logger => $logger, command => $command
    );

    foreach my $package (@$packages) {
        $inventory->addEntry(
            section => 'SOFTWARES',
            entry   => $package
        );
    }
}

sub _getPackagesList {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @packages;
    foreach my $line (@lines) {
        next unless $line =~ /^(.*)-([0-9]+.*)/;
        push @packages, {
            NAME    => $1,
            VERSION => $2,
        };
    }

    return \@packages;
}

# http://forge.fusioninventory.org/issues/852
sub _equeryNeedsWildcard {
    my ($major, $minor) = getFirstMatch(
        command => 'equery -V',
        pattern => qr/^equery ?\((\d+)\.(\d+)\.\d+\)/,
        @_
    );

    # true starting from version 0.3
    return compareVersion($major, $minor, 0, 3);
}

1;
