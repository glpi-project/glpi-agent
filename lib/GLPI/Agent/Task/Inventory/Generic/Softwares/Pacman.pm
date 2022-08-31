package GLPI::Agent::Task::Inventory::Generic::Softwares::Pacman;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('pacman');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $packages = _getPackagesList(
        logger  => $logger,
        command => 'pacman -Qqi'
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
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @packages;
    my $package;
    my $index = 1;
    my %months = map { $_ => $index ++ } qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    foreach my $line (@lines) {
        next unless $line;
        next unless $line =~ /^(\S[^:]*):\s*(.*)$/;

        my $key   = $1;
        my $value = $2;
        $key =~ s/\s+$//;

        if ($key eq 'Name') {
            push @packages, $package
                if $package;
            $package = {
                NAME => $value
            };
        } elsif ($key eq 'Version' && $value) {
            $value =~ s/^\d+://;
            $package->{VERSION} = $value;
        } elsif ($key eq 'Description' && $value) {
            $package->{COMMENTS} = $value;
        } elsif ($key eq 'Architecture' && $value) {
            $package->{ARCH} = $value;
        } elsif ($key eq 'Install Date' && $value) {
            my ($month, $day, $year) = $value =~ /^\w+\s+(\w+)\s+(\d+)\s+[\d:]+\s+(\d+)$/;
            next unless $month && $months{$month};
            $package->{INSTALLDATE} = sprintf("%02d/%02d/%d", $day, month($month), $year);
        } elsif ($key eq 'Installed Size' && $value) {
            if ($value =~ /^([\d.]+)\s+(\w+)$/) {
                my $size =  $2 eq 'KiB' ? $1 * 1024 :
                            $2 eq 'MiB' ? $1 * 1048576 :
                            $2 eq 'GiB' ? $1 * 1073741824 :
                            $1;
                $package->{FILESIZE} = int($size);
            }
        } elsif ($key eq 'Groups' && $value && $value ne 'None') {
            $package->{SYSTEM_CATEGORY} = join(',', split(/\s+/,$value));
        }
    }

    # Add last software
    push @packages, $package
        if $package;

    return \@packages;
}

1;
