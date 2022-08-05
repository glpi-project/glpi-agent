package GLPI::Agent::Tools::Screen::Samsung;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::Screen';

# Well-known eisa_id for which wee need to revert serial and altserial
my $eisa_id_match = qr/0572|0694|06b9|0833|0835|0978|09c6|09c7|0b66|0bc9|0c7b|0ca3|0ca5|0d1a|0e0f|0e1e/ ;
# For this model, prefix is in reverse order
my $eisa_id_match_2 = qr/0e5a$/ ;
# For this model, the serial should be a decimal, not in hexadecimal
my $eisa_id_match_3 = qr/0c18$/ ;

sub serial {
    my ($self) = @_;

    # Revert serial and altserial when eisa_id matches
    return $self->_altserial if ($self->eisa_id =~ $eisa_id_match);
    return $self->_altserial_2 if ($self->eisa_id =~ $eisa_id_match_2);
    return $self->_altserial_3 if ($self->eisa_id =~ $eisa_id_match_3);

    return $self->{_serial};
}

sub altserial {
    my ($self) = @_;

    return $self->{_altserial} if $self->{_altserial};

    # Revert serial and altserial when eisa_id matches
    return $self->{_altserial} = ($self->eisa_id =~ $eisa_id_match || $self->eisa_id =~ $eisa_id_match_2) ?
        $self->{_serial} : $self->_altserial;
}

sub _altserial {
    my ($self) = @_;

    my $serial1 = $self->{edid}->{serial_number};
    my $serial2 = $self->{edid}->{serial_number2}->[0]
        or return '';

    return
        chr(($serial1 >> 24)% 256) .
        chr(($serial1 >> 16)% 256) .
        chr(($serial1 >> 8 )% 256) .
        chr( $serial1       % 256) .
        $serial2 ;
}

sub _altserial_2 {
    my ($self) = @_;

    my $serial1 = $self->{edid}->{serial_number};
    my $serial2 = $self->{edid}->{serial_number2}->[0]
        or return '';

    return
        chr( $serial1       % 256) .
        chr(($serial1 >> 8 )% 256) .
        chr(($serial1 >> 16)% 256) .
        chr(($serial1 >> 24)% 256) .
        $serial2 ;
}

sub _altserial_3 {
    my ($self) = @_;

    return $self->{edid}->{serial_number};
}

1;
