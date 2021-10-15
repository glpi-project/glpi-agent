package FusionInventory::Agent::Task::Inventory::Generic::Softwares::Nix;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

sub isEnabled {
    return canRun('nix-store');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $command = 'nix-store --gc --print-live';
    my $packages = _getPackagesList(
        logger => $logger, command => $command
    );
    return unless $packages;

    foreach my $package (@$packages) {
        $inventory->addEntry(
            section => 'SOFTWARES',
            entry   => $package
        );
    }
}

sub _getPackagesList {
    my $handle = getFileHandle(@_);
    return unless $handle;

    my @packages;
    my %seen   = ();
    while (my $line = <$handle>) {
        chomp $line;
        next unless $line =~ m%^/nix/store/[^-]+-(.+)-(\d+(\.\d+)*)$%;

        my $package = {
            NAME        => $1,
            VERSION     => $2,
            FROM        => 'nix'
        };

        next if $seen{$package->{NAME} . '-' . $package->{VERSION}}++;

        push @packages, $package;
    }

    close $handle;

    return \@packages;
}

1;
