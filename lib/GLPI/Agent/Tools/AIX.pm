package GLPI::Agent::Tools::AIX;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

our @EXPORT = qw(
    getLsvpdInfos
    getAdaptersFromLsdev
);

sub getLsvpdInfos {
    my (%params) = (
        command => 'lsvpd',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @devices;
    my $device;

    # skip first lines
    while (1) {
        my $line = shift @lines;
        last unless defined($line);
        last if $line =~ /^\*FC \?+/;
    }

    foreach my $line (@lines) {
        if ($line =~ /^\*FC \?+/) {
            # block delimiter
            push @devices, $device;
            undef $device;
            next;
        }

        next unless $line =~ /^\* ([A-Z]{2}) \s+ (.*\S)/x;
        $device->{$1} = $2;
    }

    # last device
    push @devices, $device;

    return @devices;
}

sub getAdaptersFromLsdev {
    my (%params) = (
        command => 'lsdev -Cc adapter -F "name:type:description"',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @adapters;

    foreach my $line (@lines) {
        my @info = split(/:/, $line);
        push @adapters, {
            NAME        => $info[0],
            TYPE        => $info[1],
            DESCRIPTION => $info[2]
        };
    }

    return @adapters;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::AIX - AIX generic functions

=head1 DESCRIPTION

This module provides some generic functions for AIX.

=head1 FUNCTIONS

=head2 getLsvpdInfos

Returns a list of vital product data infos, extracted from lsvpd output.

@infos = (
    {
        DS => 'System VPD',
        YL => 'U9111.520.65DEDAB',
        RT => 'VSYS',
        FG => 'XXSV',
        BR => 'O0',
        SE => '65DEDAB',
        TM => '9111-520',
        SU => '0004AC0BA763',
        VK => 'ipzSeries'
    },
    ...
)

=head2 getAdaptersFromLsdev

Returns a list of adapters, extracted from lsdev -Cc adapter output
