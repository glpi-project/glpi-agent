package FusionInventory::Agent::Task::Inventory::Linux::ARM::Board;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Linux;

sub isEnabled {
    return -r '/proc/cpuinfo';
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

    my $handle = getFileHandle(%params);

    my $infos;

    # Does the inverse of FusionInventory::Agent::Tools::Linux::getCPUsFromProc()
    while (my $line = <$handle>) {
        if ($line =~ /^([^:]+\S) \s* : \s (.+)/x) {
            $infos->{lc($1)} = trimWhitespace($2);
        } elsif ($line =~ /^$/) {
            # Quit if not a cpu
            last unless ($infos && (exists($infos->{processor}) || exists($infos->{cpu})));
            undef $infos;
        }
    }
    close $handle;

    return $infos
        unless ($infos && (exists($infos->{processor}) || exists($infos->{cpu})));
}

1;
