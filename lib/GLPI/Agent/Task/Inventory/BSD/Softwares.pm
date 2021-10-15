package GLPI::Agent::Task::Inventory::BSD::Softwares;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "software";

sub isEnabled {
    return canRun('pkg_info') || canRun('pkg');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $packages =
        _getPackagesList(logger => $logger, command => 'pkg_info') ||
        _getPackagesList(logger => $logger, command => 'pkg info');
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
    while (my $line = <$handle>) {
        next unless $line =~ /^(\S+) - (\S+) \s+ (.*)/x;
        push @packages, {
            NAME     => $1,
            VERSION  => $2,
            COMMENTS => $3
        };
    }

    close $handle;

    return @packages ? \@packages : undef;
}

1;
