package GLPI::Agent::Tools::Expiration;

use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw(
    setExpirationTime
    getExpirationTime
);

my $_expirationTime;

sub setExpirationTime {
    my (%params) = @_;

    if ($params{timeout}) {
        $_expirationTime = time + $params{timeout};
        return 1;
    } elsif ($params{expiration}) {
        $_expirationTime = $params{expiration};
        return 1;
    } else {
        undef $_expirationTime;
        return 0;
    }
}

sub getExpirationTime {
    return $_expirationTime || 0;
}

1;
__END__

=head1 NAME

GLPI::Agent::Expiration - Expiration functions

=head1 DESCRIPTION

This module provides some time-out related functions.

=head1 FUNCTIONS

=head2 setExpiration(%params)
Set current expiration time from now if a timeout param is found in provided hash
or from expiration param and then return true, otherwise, undefine current
expiration and return false.

=head2 getExpiration()

Get current expiration time, to be compared to time returned value.
