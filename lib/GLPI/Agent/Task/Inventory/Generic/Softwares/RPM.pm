package FusionInventory::Agent::Task::Inventory::Generic::Softwares::RPM;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

sub isEnabled {
    return canRun('rpm');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $command =
        'rpm -qa --queryformat \'' .
        '%{NAME}\t' .
        '%{ARCH}\t' .
        '%{VERSION}-%{RELEASE}\t' .
        '%{INSTALLTIME}\t' .
        '%{SIZE}\t' .
        '%{VENDOR}\t' .
        '%{SUMMARY}\t' .
        '%{GROUP}\n' .
        '\'';

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
    while (my $line = <$handle>) {
        chomp $line;
        my @infos = split("\t", $line);
        my $package = {
            NAME        => $infos[0],
            ARCH        => $infos[1],
            VERSION     => $infos[2],
            FILESIZE    => $infos[4],
            COMMENTS    => $infos[6],
            FROM        => 'rpm',
            SYSTEM_CATEGORY => $infos[7]
        };

        my ($year, $month, $day) = (localtime($infos[3]))[5, 4, 3];
        $package->{INSTALLDATE}  = sprintf(
            "%02d/%02d/%04d", $day, $month + 1, $year + 1900
        );
        $package->{PUBLISHER} = $infos[5] if $infos[5] ne '(none)';
        push @packages, $package;
    }

    close $handle;

    return \@packages;
}

1;
