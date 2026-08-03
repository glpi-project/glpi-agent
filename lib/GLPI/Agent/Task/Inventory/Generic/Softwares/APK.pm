package GLPI::Agent::Task::Inventory::Generic::Softwares::APK;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Encode qw(decode);

use GLPI::Agent::Tools;

# Alpine Package Keeper (apk) installed packages database.
# Reading it directly is faster than forking "apk" (which parses the very same
# file) and more robust, as the package name and version are stored in separate
# fields instead of a single "name-version" token that would need to be split.
my $installed_db = '/lib/apk/db/installed';

sub isEnabled {
    return canRun('apk') && has_file($installed_db);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $packages = _getPackagesList(
        logger => $logger,
        file   => $installed_db,
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

    # The apk installed database describes each package as a block of
    # "<key>:<value>" lines, blocks being separated by an empty line.
    # Relevant keys:
    #   P: package name
    #   V: version
    #   A: architecture
    #   I: installed size (in bytes)
    #   T: package description
    #   m: maintainer
    my @packages;
    my $package;

    foreach my $line (map { decode("UTF-8", $_) } @lines) {
        if ($line eq '') {
            push @packages, $package
                if $package && $package->{NAME};
            undef $package;
            next;
        }

        next unless $line =~ /^(\w):(.*)$/;
        my ($key, $value) = ($1, $2);

        if ($key eq 'P') {
            $package = {
                NAME => $value,
                FROM => 'apk',
            };
        } elsif (!$package) {
            next;
        } elsif ($key eq 'V') {
            $package->{VERSION} = $value;
        } elsif ($key eq 'A') {
            $package->{ARCH} = $value;
        } elsif ($key eq 'I' && $value =~ /^\d+$/) {
            $package->{FILESIZE} = $value;
        } elsif ($key eq 'T' && length($value)) {
            $package->{COMMENTS} = $value;
        } elsif ($key eq 'm' && length($value)) {
            $package->{PUBLISHER} = $value;
        }
    }

    # Add last package if the database does not end with an empty line
    push @packages, $package
        if $package && $package->{NAME};

    return \@packages;
}

1;
