package FusionInventory::Agent::Tools::Screen::Acer;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Tools::Screen';

# Well-known eisa_id for which wee need to revert serial and altserial
my $eisa_id_match = qr/(0018|0020|0024|00a3|00A8|00d2|00db|00f7|02d4|032e|0330|0337|03de|0468|0503|0618|0783|7883|ad49|adaf)$/ ;

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
    my $serial2 = $self->{edid}->{serial_number2}->[0];

    # Split serial2
    my $part1 = substr($serial2, 0, 8);
    my $part2 = substr($serial2, 8, 4);

    # Assemble serial1 with serial2 parts
    return $part1 . sprintf("%08x", $serial1) . $part2;
}

1;
