package GLPI::Agent::Tools::Screen::Goldstar;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::Screen';

# Well-known eisa_id for which wee need to revert serial and altserial
my $eisa_id_match = qr/4b21$/ ;

sub serial {
    my ($self) = @_;

    # Revert serial and altserial when eisa_id matches
    return $self->_altserial if ($self->eisa_id =~ $eisa_id_match);

    return $self->{_serial};
}

sub altserial {
    my ($self) = @_;

    return $self->{_altserial} if $self->{_altserial};

    # Revert serial and altserial when eisa_id matches
    return $self->{_altserial} = $self->eisa_id =~ $eisa_id_match ?
        $self->{_serial} : $self->_altserial;
}

sub _altserial {
    my ($self) = @_;

    my $serial1 = $self->{edid}->{serial_number};

    # split serial in two parts
    my ($high, $low) = $serial1 =~ /(\d+) (\d\d\d)$/x;

    return 0 unless defined($high) && defined($low);

    # translate the first part using a custom alphabet
    my @alphabet = split(//, "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ");
    my $base     = scalar @alphabet;

    return 0 if $high/$base > $#alphabet;

    return $alphabet[$high / $base] . $alphabet[$high % $base] . $low;
}

1;
