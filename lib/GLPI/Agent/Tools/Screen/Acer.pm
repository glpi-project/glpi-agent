package GLPI::Agent::Tools::Screen::Acer;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::Screen';

# Well-known eisa_id for which we need to revert serial and altserial
my $eisa_id_match;
{
    my @models;
    foreach my $line (<DATA>) {
        next unless $line =~ /^\s+([0-9a-f]{4})\s+/;
        push @models, $1;
    }
    close(DATA);

    my $eisa_id_match_str = join('|', @models);
    $eisa_id_match = qr/($eisa_id_match_str)$/i ;
}

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

__DATA__
# List of model indexed by their hexdecimal model number in EDID block
    0018
    0019    V173
    0020
    0024    Acer V193
    004b    Acer V193W
    004c    Acer V193
    00a3    V243H
    00a8
    00d2    B243H
    00db    S273HL
    00f7    V193
    02d4    Acer G236HL
    0319    Acer H226HQL
    032e    Acer V246HL
    0330    Acer B226HQL
    0335    V226HQL
    0337    B226HQL
    03de    G227HQL
    0468    Acer KA240HQ
    0503    R221Q
    0512    K222HQL
    0523    K272HL
    056b    Acer ET221Q
    057d    SA220Q
    0618    Acer B196HQL
    0783
    7883
    ad49    Acer AL1916
    ad51    Acer AL1716
    adaf
