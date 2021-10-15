package GLPI::Agent::Tools::PartNumber::Samsung;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::PartNumber';

# See https://www.samsung.com/semiconductor/global.semi/file/resource/2018/06/DDR4_Product_guide_May.18.pdf
# https://www.samsung.com/semiconductor/global.semi/file/resource/2017/11/DDR3_Product_guide_Oct.16[2]-0.pdf

use constant match_re       => qr/^(?:
    M[34]..([AB]).......-.(..).?    |
    K4([AB]).......-..(..)(?:...)?
)$/x;

use constant category       => "memory";
use constant manufacturer   => "Samsung";

sub init {
    my ($self, $type_match, $speed_match ) = @_;

    my %speeds = qw(
        F7  800     F8  1066    H9  1333    K0  1600    MA  1866    NB  2133
        PB  2133    RC  2400    TD  2666    RB  2133    TC  2400    WD  2666
        VF  2933    WE  3200    YF  2933    AE  3200
    );
    $self->{_speed} = $speeds{$speed_match};

    my %types = qw(
        B   DDR3    A   DDR4
    );
    $self->{_type} = $types{$type_match};

    return $self;
}

1;
