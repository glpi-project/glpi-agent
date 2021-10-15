package GLPI::Agent::Tools::PartNumber::Elpida;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::PartNumber';

# Based on specs from Elpida Memory, Inc 2002-2012 - ECT-TS-2039 June 2012

use constant match_re       => qr/^E([BCD])(.).{8}.?-(..).?.?(?:-..)?$/;

use constant category       => "memory";
use constant manufacturer   => "Elpida";

sub init {
    my ($self, $bcd_match, $type_match, $speed_match ) = @_;

    my %speeds = (
        B   => { qw(
            DJ  10660    GN  12800
        ) },
        C   => { qw(
            50  400
        ) },
        D   => { qw(
            AE  1066    DJ  1333    MU  2133    GN  1600    JS  1866    1J  1066
            8E  800
        ) },
    );
    my $speeds = $speeds{$bcd_match} // {};
    $self->{_speed} = $speeds->{$speed_match};

    my %types = qw(
        M   DDR     E   DDR2    J   DDR3    B   DDR2
    );
    $self->{_type} = $types{$type_match};

    return $self;
}

1;
