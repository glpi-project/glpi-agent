package GLPI::Agent::Task::Inventory::Generic::Softwares::Snap;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use YAML::Tiny;

use GLPI::Agent::Tools;

sub isEnabled {
    # Snap is not supported on AIX and the command has another usage
    return 0 unless OSNAME ne 'aix' && canRun('snap');

    # Try to check if snapd is active/running
    if (canRun('pgrep')) {
        if (canRun('systemcl') && getFirstLine(command => "pgrep -g 1 -x systemd")) {
            my $status = getFirstLine(command => "systemctl is-active snapd");
            return 0 if defined($status) && $status =~ /inactive/;
        } elsif (!getFirstLine(command => "pgrep -x snapd")) {
            return 0;
        }
    }

    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Don't try to contact snapd if said not available by "snap version"
    my $snapd = getFirstMatch(
        logger  => $logger,
        command => 'snap version',
        pattern => qr/^snapd\s+(\S+)$/,
    );
    return if $snapd && $snapd eq 'unavailable';

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

    my @lines = getAllLines(%params)
        or return;

    my @packages;
    foreach my $line (@lines) {
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
        # Don't check install date during unittest
        if (!$params{file} && has_folder($folder)) {
            my $st = FileStat($folder);
            my ($year, $month, $day) = (localtime($st->mtime))[5, 4, 3];
            $snap->{INSTALLDATE}  = sprintf(
                "%02d/%02d/%04d", $day, $month + 1, $year + 1900
            );
        }

        push @packages, $snap;
    }

    return \@packages;
}

sub _getPackagesInfo {
    my (%params) = @_;

    my $snap = delete $params{snap};
    _parseSnapYaml(
        logger  => $params{logger},
        snap    => $snap,
        file    => delete $params{file}
    );

    if ($params{command}) {
        # snap info command may wrongly output some long infos
        local $ENV{COLUMNS} = 100;

        _parseSnapYaml(
            logger  => $params{logger},
            snap    => $snap,
            command => $params{command}
        );
    }

    return unless $snap && $snap->{NAME};

    # Cleanup publisher from 'starred' if verified
    $snap->{PUBLISHER} =~ s/[*]$// if $snap->{PUBLISHER};
    delete $snap->{PUBLISHER} if $snap->{PUBLISHER} =~ /^[-]+$/
}

my %mapping = qw(
    name        NAME
    publisher   PUBLISHER
    summary     COMMENTS
    contact     HELPLINK
);
my $mapping_match = join("|", sort keys(%mapping));
my $mapping_match_qr = qr/($mapping_match):\s+(.+)$/;

sub _parseSnapYaml {
    my (%params) = @_;

    my $snap = delete $params{snap};
    my $arch = 0;

    foreach my $line (getAllLines(%params)) {
        if ($arch) {
            ($snap->{ARCH}) = $line =~ /^\s*-\s(.*)$/;
            $arch = 0;
        } elsif ($line =~ /^architectures:/) {
            $arch = 1;
        } elsif ($line =~ /^[\s-]/) {
            next;
        } elsif ($line =~ /^installed:\s+.*\(.*\)\s+(\d+\S+)/) {
            $snap->{FILESIZE} = getCanonicalSize($1, 1024) * 1048576;
        } elsif ($line =~ $mapping_match_qr) {
            $snap->{$mapping{$1}} = $2;
        }
    }
}

1;
