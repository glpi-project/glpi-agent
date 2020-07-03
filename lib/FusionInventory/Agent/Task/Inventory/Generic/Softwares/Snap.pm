package FusionInventory::Agent::Task::Inventory::Generic::Softwares::Snap;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use File::stat;
use YAML::Tiny;

use FusionInventory::Agent::Tools;

sub isEnabled {
    return canRun('snap');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $packages = _getPackagesList(
        logger  => $logger,
        command => 'snap list --color never',
    );
    return unless $packages;

    foreach my $snap (@{$packages}) {
        my $rev = delete $snap->{_REVISION};
        _getPackagesInfo(
            logger  => $logger,
            snap    => $snap,
            command => 'snap info --color never --abs-time '.$snap->{NAME},
            file    => '/snap/'.$snap->{NAME}.'/'.$rev.'/meta/snap.yaml',
        );
        $inventory->addEntry(
            section => 'SOFTWARES',
            entry   => $snap
        );
    }
}

sub _getPackagesList {
    my (%params) = @_;

    my $handle = getFileHandle(%params);
    return unless $handle;

    my @packages;
    while (my $line = <$handle>) {
        chomp $line;
        my @infos = split(/\s+/, $line)
            or next;

        # Skip header
        next if $infos[0] eq 'Name' && $infos[1] eq 'Version';

        # Skip base and snapd
        next if $infos[5] && $infos[5] =~ /^base|core|snapd$/;

        my $snap = {
            NAME            => $infos[0],
            VERSION         => $infos[1],
            _REVISION       => $infos[2],
            PUBLISHER       => $infos[4],
            FROM            => 'snap'
        };

        my $folder = "/snap/".$snap->{NAME};
        if (-d $folder) {
            my $st = stat($folder);
            my ($year, $month, $day) = (localtime($st->mtime))[5, 4, 3];
            $snap->{INSTALLDATE}  = sprintf(
                "%02d/%02d/%04d", $day, $month + 1, $year + 1900
            );
        }

        push @packages, $snap,
    }
    close $handle;

    return \@packages;
}

sub _getPackagesInfo {
    my (%params) = @_;

    my $snap = delete $params{snap};
    my $lines = getAllLines(%params)
        or return;

    my @output;
    if ($params{file} && $params{command}) {
        delete $params{file};
        @output = getAllLines(%params);
    }

    my $yaml  = YAML::Tiny->read_string($lines);
    my $infos = $yaml->[0]
        or return;

    return unless $infos->{name};

    if (@output && !$infos->{publisher}) {
        my ($publisher) = map { /^publisher: (.*)$/ } grep { /^publisher:/ } @output;
        $infos->{publisher} = $publisher if $publisher;
    }
    $snap->{PUBLISHER} = $infos->{publisher}
        if $infos->{publisher};
    # Cleanup publisher from 'starred' if verified
    $snap->{PUBLISHER} =~ s/[*]$// if $snap->{PUBLISHER};

    $snap->{COMMENTS}  = $infos->{summary};

    if (@output && !$infos->{contact}) {
        my ($contact) = map { /^contact: (.*)$/ } grep { /^contact:/ } @output;
        $infos->{contact} = $contact if $contact;
    }
    $snap->{HELPLINK} = $infos->{contact} if $infos->{contact};

    # Find installed size
    if (@output && !$infos->{installed}) {
        my ($installed) = map { /^installed: (.*)$/ } grep { /^installed:/ } @output;
        $infos->{installed} = $installed if $installed;
    }
    return unless $infos->{installed};
    my ($size) = $infos->{installed} =~ /\(.*\)\s+(\d+\S+)/;
    $snap->{FILESIZE} = getCanonicalSize($size, 1024) * 1048576
        if $size;
}

1;
