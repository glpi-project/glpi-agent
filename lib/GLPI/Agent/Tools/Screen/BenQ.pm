package GLPI::Agent::Tools::Screen::BenQ;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::Screen';

use GLPI::Agent::Tools;

sub serial {
    my ($self) = @_;

    my $prefix;
    if ($self->{edid}->{serial_number2}) {
        $prefix = unpack("Z*", pack("L", $self->{edid}->{serial_number}));
        undef $prefix unless $prefix =~ /^([A-Z]+)$/;
    }

    return $self->{_fixed_serial} = $prefix ? $prefix.$self->{_serial} : $self->{_serial};
}

sub altserial {
    my ($self) = @_;

    return if empty($self->{_fixed_serial}) || (length($self->{_fixed_serial}) == length($self->{_serial}) && $self->{_fixed_serial} eq $self->{_serial});

    return $self->{_serial};
}

1;
