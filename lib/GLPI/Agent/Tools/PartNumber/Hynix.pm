package GLPI::Agent::Tools::PartNumber::Hynix;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::PartNumber';

# See https://www.skhynix.com/eng/support/technicalSupport.jsp

use constant match_re   => qr/^HY?[59M]([ADHPT])[123458ABCNQ]........?.?-(..).?$/;

use constant category       => "memory";
use constant manufacturer   => "Hynix";
use constant mm_id          => "Bank 1, Hex 0xAD";

sub init {
    my ($self, $type_match, $speed_match ) = @_;

    my %speeds = qw(
        K2  266     K3  266     J3  333     E3  400     E4  400     F4  500
        G7  1066    H9  1333    TE  2133    UL  2400    FA  500     FB  500
        PB  1600    RD  1866    TF  2133    UH  2400    VK  2666    XN  3200
        NL  3200    NM  3733    NE  4266    VN  2666    WM  2933    WR  2933
        XS  3200
    );
    $self->{_speed} = $speeds{$speed_match};

    my %types = qw(
        D   DDR     P   DDR2    T   DDR3    A   DDR4    H   LPDDR4
    );
    $self->{_type} = $types{$type_match};

    return $self;
}

1;
