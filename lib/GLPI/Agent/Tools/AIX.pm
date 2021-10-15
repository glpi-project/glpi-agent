package FusionInventory::Agent::Tools::AIX;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use Memoize;

our @EXPORT = qw(
    getLsvpdInfos
    getAdaptersFromLsdev
);

memoize('getLsvpdInfos');
memoize('getAdaptersFromLsdev');

sub getLsvpdInfos {
    my (%params) = (
        command => 'lsvpd',
        @_
    );

    my $handle = getFileHandle(%params);
    return unless $handle;

    my @devices;
    my $device;

    # skip first lines
    while (my $line = <$handle>) {
        last if $line =~ /^\*FC \?+/;
    }

    while (my $line = <$handle>) {
        if ($line =~ /^\*FC \?+/) {
            # block delimiter
            push @devices, $device;
            undef $device;
            next;
        }

        chomp $line;
        next unless $line =~ /^\* ([A-Z]{2}) \s+ (.*\S)/x;
        $device->{$1} = $2;
    }
    close $handle;

    # last device
    push @devices, $device;

    return @devices;
}

sub getAdaptersFromLsdev {
    my (%params) = (
        command => 'lsdev -Cc adapter -F "name:type:description"',
        @_
    );

    my $handle = getFileHandle(%params);
    return unless $handle;

    my @adapters;

    while (my $line = <$handle>) {
        chomp $line;
        my @info = split(/:/, $line);
        push @adapters, {
            NAME        => $info[0],
            TYPE        => $info[1],
            DESCRIPTION => $info[2]
        };
    }
    close $handle;

    return @adapters;
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Tools::AIX - AIX generic functions

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
