package GLPI::Agent::Tools::Screen::BenQ;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::Screen';

use GLPI::Agent::Tools;

sub serial {
    my ($self) = @_;

    my $prefix = unpack("Z*", pack("L", $self->{edid}->{serial_number}));

    my $cleanprefix = $prefix;
    $cleanprefix =~ s/[^A-Z]//g;

    return $self->{_fixed_serial} = length($prefix) == length($cleanprefix) ? $prefix.$self->{_serial} : $self->{_serial};
}

sub altserial {
    my ($self) = @_;

    return if empty($self->{_fixed_serial}) || (length($self->{_fixed_serial}) == length($self->{_serial}) && $self->{_fixed_serial} eq $self->{_serial});

    return $self->{_serial};
}

1;
