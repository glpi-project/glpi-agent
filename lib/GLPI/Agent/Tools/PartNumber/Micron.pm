package GLPI::Agent::Tools::PartNumber::Micron;

use strict;
use warnings;

use parent 'GLPI::Agent::Tools::PartNumber';

# https://www.micron.com/products/dram-modules/rdimm/part-catalog

use constant match_re => qr/^
    (?:MTA?)?
    \d+
    ([AHJK])
    [DST]
    [FQS]
    \d+G?               # depth: 256MB, 1G, etc.
    72                  # width: x72
    [AP](?:[DS])?Z
    \-
/x;

use constant category     => 'memory';
use constant manufacturer => 'Micron';

sub init {
    my ($self, $type_match) = @_;

    my %types = qw(
        H   DDR2
        J   DDR3    K   DDR3
        A   DDR4
    );
    $self->{_type} = $types{$type_match};

    return $self;
}

1;
