package GLPI::Agent::Tools::PartNumber::Dell;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::PartNumber';

use constant match_re       => qr/^([0-9A-Z]{6})([A-B]\d{2})$/;

use constant category       => "controller";
use constant manufacturer   => "Dell";

sub init {
    my ($self, $partnum, $revision) = @_;

    $self->{_partnumber} = $partnum;
    $self->{_revision}   = $revision;

    return $self;
}

1;
