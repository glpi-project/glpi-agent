package GLPI::Agent::Tools::Screen::Philips;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::Screen';

# Handles case monitor doesn't report serial2 in edid while it is connected
# throught HDMI port. In that case, we uses serial1 as an integer, not hex.

sub _has_serial_number2 {
    my ($self) = @_;

    return exists($self->{edid}->{serial_number2}) &&
            defined($self->{edid}->{serial_number2}) &&
            $self->{edid}->{serial_number2} ;
}

sub serial {
    my ($self) = @_;

    # Revert serial and altserial when no serial2 found
    return $self->_altserial unless $self->_has_serial_number2();

    return $self->{_serial};
}

sub altserial {
    my ($self) = @_;

    return $self->{_altserial} if exists($self->{_altserial});

    # Revert serial and altserial when no serial2 found
    return $self->{_altserial} = $self->_has_serial_number2() ?
        $self->_altserial : $self->{_serial} ;
}

sub _altserial {
    my ($self) = @_;

    my $serial1 = sprintf("%06d", $self->{edid}->{serial_number});

    # Don't report altserial if current serial still includes it
    my $altserial =  $self->{_serial} =~ m/$serial1$/ ? undef : $serial1 ;

    return $altserial;
}

1;
