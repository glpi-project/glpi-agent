package GLPI::Agent::Task::Inventory::Generic::Softwares::Deb;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('dpkg-query');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # binary:Package is available since dpkg-query 1.16.2
    # db-fsys:Last-Modified field is available since dpkg-query 1.19.3
    my $showformat = join("\t", map { '${'.$_.'}' } qw(
        Package Architecture Version Installed-Size Section Status binary:Package db-fsys:Last-Modified
    ));

    my $command = [ 'dpkg-query', '--show', "--showformat", $showformat."\n" ];

    my $packages = _getPackagesList(
        logger => $logger, command => $command
    );
    return unless $packages;

    # mimic RPM inventory behaviour, as GLPI aggregates software
    # based on name and publisher
    my $publisher = getFirstMatch(
        logger  => $logger,
        pattern => qr/^Distributor ID:\s(.+)/,
        command => 'lsb_release -i',
    );

    foreach my $package (@$packages) {
        $package->{PUBLISHER} = $publisher;
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
        # skip descriptions
        next if $line =~ /^ /;
        my @infos = split("\t", $line);

        # Only keep as installed package if status matches
        if ($infos[5] && $infos[5] !~ / installed$/) {
            $params{logger}->debug(
                "Skipping $infos[0] package as not installed, status='$infos[5]'"
            ) if $params{logger};
            next;
        }

        my $package = {
            NAME        => $infos[0],
            ARCH        => $infos[1],
            VERSION     => $infos[2],
            FILESIZE    => $infos[3] =~ /^\d+/ ? int($infos[3]*1024) : 0,
            FROM        => 'deb',
            SYSTEM_CATEGORY => $infos[4]
        };

        # Handle INSTALLDATE
        # 1. Try to use ${db-fsys:Last-Modified} as available since dpkg-query 1.19.3
        my $datetime = $infos[7];
        # Don't try stat method during tests
        if ((empty($datetime) || $datetime !~ /^\d+/) && empty($params{file})) {
            # 2. Fallback on checking .list package file modification time
            my $st;
            if (empty($infos[6])) {
                # Try 2 files if ${binary:Package} is not set as only available since dpkg-query 1.16.2
                my $listfile = "/var/lib/dpkg/info/".$infos[0].".list";
                $st = FileStat($listfile);
                unless ($st) {
                    # Eventually try list file with architecture tag
                    $listfile = "/var/lib/dpkg/info/".$infos[0].":".$infos[1].".list";
                    $st = FileStat($listfile);
                }
            } else {
                # Directly use ${binary:Package} as only available since 1.16.2
                my $listfile = "/var/lib/dpkg/info/".$infos[6].".list";
                $st = FileStat($listfile);
            }
            $datetime = $st->mtime if defined($st);
        }
        if (!empty($datetime) && $datetime =~ /^\d+$/) {
            my ($year, $month, $day) = (localtime(int($datetime)))[5, 4, 3];
            $package->{INSTALLDATE}  = sprintf(
                "%02d/%02d/%04d", $day, $month + 1, $year + 1900
            );
        }

        push @packages, $package;
    }

    return \@packages;
}

1;
