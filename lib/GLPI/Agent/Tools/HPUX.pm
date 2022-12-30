package GLPI::Agent::Tools::HPUX;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

our @EXPORT = qw(
    getInfoFromMachinfo
    isHPVMGuest
);

sub getInfoFromMachinfo {
    my (%params) = (
        command => '/usr/contrib/bin/machinfo',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my $info;
    my $current;
    foreach my $line (@lines) {

        #key: value
        if ($line =~ /^ (\S [^:]+) : \s+ (.*\S)/x) {
            $info->{$1} = $2;
            next;
        }

        #  key: value
        if ($line =~ /^ \s+ (\S [^:]+) : \s+ (.*\S)/x) {
            $info->{$current}->{lc($1)} = $2;
            next;
        }

        #  key = value
        if ($line =~ /^ \s+ (\S [^=]+) \s+ = \s+ (.*\S)/x) {
            $info->{$current}->{lc($1)} = $2;
            next;
        }

        #  value
        if ($line =~ /^ \s+ (.*\S)/x) {
            # hack for CPUinfo:
            # accumulate new lines if current node is not an hash
            if ($info->{$current}) {
                $info->{$current} .= " $1" if ! ref $info->{$current};
            } else {
                $info->{$current} = $1;
            }
            next;
        }

        #key:
        if ($line =~ /^ (\S [^:]+) :$/x) {
            $current = $1;
            next;
        }
    }

    return $info;
}

sub isHPVMGuest {
    return getFirstMatch(
        command => 'hpvminfo',
        pattern => qr/HPVM guest/
    );
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::HPUX - HPUX generic functions

=head1 DESCRIPTION

This module provides some generic functions for HPUX.

=head1 FUNCTIONS

=head2 getInfoFromMachinfo

Returns a structured view of machinfo output.
