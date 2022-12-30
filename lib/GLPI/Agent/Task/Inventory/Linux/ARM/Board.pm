package GLPI::Agent::Task::Inventory::Linux::ARM::Board;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "bios";

sub isEnabled {
    return canRead('/proc/cpuinfo');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $bios = _getBios( logger => $params{logger});

    $inventory->setBios($bios) if $bios;
}

sub _getBios {
    my (%params) = @_;

    my $bios;

    my $board = $params{board} || _getBoardFromProc( %params );

    if ($board) {
        # List of well-known inventory values we can import
        # Search for cpuinfo value from the given list
        my %infos = (
            MMODEL  => [ 'hardware' ],
            MSN     => [ 'revision' ],
            SSN     => [ 'serial' ]
        );

        # Map found informations
        foreach my $key (keys(%infos)) {
            foreach my $info (@{$infos{$key}}) {
                if ($board->{$info}) {
                    $bios = {} unless $bios;
                    $bios->{$key} = $board->{$info};
                    last;
                }
            }
        }
    }

    return $bios;
}

sub _getBoardFromProc {
    my (%params) = (
        file => '/proc/cpuinfo',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my $infos;

    # Does the inverse of GLPI::Agent::Tools::Linux::getCPUsFromProc()
    foreach my $line (@lines) {
        if ($line =~ /^([^:]+\S) \s* : \s (.+)/x) {
            $infos->{lc($1)} = trimWhitespace($2);
        } elsif ($line =~ /^$/) {
            # Quit if not a cpu
            last unless ($infos && (exists($infos->{processor}) || exists($infos->{cpu})));
            undef $infos;
        }
    }

    return $infos
        unless ($infos && (exists($infos->{processor}) || exists($infos->{cpu})));
}

1;
