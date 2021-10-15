package GLPI::Agent::Tools::Screen::Eizo;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::Screen';

sub serial {
    my ($self) = @_;

    # Don't use hex encoded serial if no serial_number2 is defined
    return $self->{edid}->{serial_number}
        unless $self->{edid}->{serial_number2} && $self->{edid}->{serial_number2}->[0];

    return $self->{_serial};
}

1;
