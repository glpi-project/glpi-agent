package GLPI::Agent::Task::Inventory::Generic::Softwares::Flatpak;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('flatpak');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $packages = _getFlatpakList(logger  => $logger);

    foreach my $flatpak (@{$packages}) {
        $flatpak = _getFlatpakInfo(
            logger  => $logger,
            flatpak => $flatpak,
        );
        next unless $flatpak;

        $inventory->addEntry(
            section => 'SOFTWARES',
            entry   => $flatpak
        );
    }
}

sub _getFlatpakList {
    my (%params) = @_;

    my @apps;

    foreach my $line (getAllLines(
        command => 'flatpak list -a --columns=application,branch,installation,name',
        %params
    )) {
        # Skip header line
        next if $line =~ /Application ID.*Name/;

        my ($appid, $branch, $mode, $name) = $line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S.*)$/
            or next;

        push @apps, {
            _BRANCH         => $branch,
            _APPID          => $appid,
            NAME            => trimWhitespace($name),
            SYSTEM_CATEGORY => $mode,
            FROM            => "flatpak"
        };
    }

    return \@apps;
}

my %mapping = qw(
    Installed       FILESIZE
    Version         VERSION
    Origin          PUBLISHER
    Arch            ARCH
    Installation    SYSTEM_CATEGORY
    Date            INSTALLDATE
);

sub _getFlatpakInfo {
    my (%params) = @_;

    my $flatpak = delete $params{flatpak};

    my $mode = $flatpak->{SYSTEM_CATEGORY};
    my $appid = delete $flatpak->{_APPID};
    my $branch = delete $flatpak->{_BRANCH};

    # $mode can be "user" or "system"
    my @infos = getAllLines(
        command => "flatpak info --$mode $appid $branch",
        %params
    )
        or return;

    foreach my $info (@infos) {
        my ($key, $value) = $info =~ /(\S+):\s+(.*)$/
            or next;

        my $keyname = $mapping{$key}
            or next;

        if ($keyname eq "FILESIZE") {
            # Convert size as bytes
            my ($size, $unit) = $value =~ /^([\d.]+).*([kMG]B)$/;
            next unless $size && $unit;
            $value = int(
                $unit eq 'kB' ? $size * 1024 :
                $unit eq 'MB' ? $size * 1048576 :
                                $size * 1073741824 # unit eq "GB"
            );
        } elsif ($keyname eq "INSTALLDATE") {
            # Example: Date: 2020-10-04 14:56:29 +0000
            my ($year, $month, $day) = $value =~ /^(\d+)-(\d+)-(\d+)\s/;
            $value = sprintf("%02d/%02d/%d", $day, $month, $year);
        }

        $flatpak->{$keyname} = $value if defined($value);
    }

    # Use branch as version if version is not set
    $flatpak->{VERSION} = $branch if $branch && ! $flatpak->{VERSION};

    # Add AppID ad comment
    $flatpak->{COMMENTS} = "AppID: $appid";

    return $flatpak;
}

1;
