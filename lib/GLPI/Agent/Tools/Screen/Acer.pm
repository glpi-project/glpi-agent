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
    my $serial2 = $self->{edid}->{serial_number2}->[0]
        or return;

    # Split serial2
    my $part1 = substr($serial2, 0, 8);
    my $part2 = substr($serial2, 8, 4);

    # Assemble serial1 with serial2 parts
    return $part1 . sprintf("%08x", $serial1) . $part2;
}

1;

__DATA__
# List of model indexed by their hexdecimal model number in EDID block
    0018    B223W
    0019    V173
    001a    V193W
    0020    B223W
    0024    Acer V193
    0026    Acer V203W
    0031    Acer V193
    004b    Acer V193W
    004c    V193
    0069    X193HQ
    0070    V223HQ
    0076    V193
    00a3    V243H
    00a8    X233H
    00c7    V203H
    00d2    B243H
    00db    S273HL
    00f7    V193
    0133    V193HQV
    0239    Acer V193L
    02cc    Acer V243HL
    02d4    Acer G236HL
    0319    Acer H226HQL
    0320    V193L
    032d    Acer V226HQL
    032e    Acer V246HL
    0330    Acer B226HQL
    0331    B246HL
    0335    V226HQL
    0337    B226HQL
    0338    B246HL
    0353    Acer B246HYL
    0363    V196L
    03de    G227HQL
    0424    Acer V246HQL
    042e    Acer K242HQL
    0468    Acer KA240HQ
    046f    R240HY
    047b    Acer CB241H
    0480    V276HL
    0503    R221Q
    0512    K222HQL
    0523    K272HL
    056b    Acer ET221Q
    057d    SA220Q
    057f    SA240Y
    0618    Acer B196HQL
    0771    B247Y
    0772    V247Y
    0783    AL1923
    033a    B226WL
    1228    ACER P1206P
    1701    ACER P1203
    1716    Acer P1283
    2309    Acer X125H
    2311    Acer H6517ABD
    2608    Acer X128H
    2708    Acer XGA PJ
    5401    ACER P5260i
    56ad    AL1717
    7883
    ad46    AL1716
    ad49    Acer AL1916
    ad51    Acer AL1716
    ad72    Acer AL1717
    ad73    Acer AL1917
    ad80    AL1916W
    adaf    P243W
