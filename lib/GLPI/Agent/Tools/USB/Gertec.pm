package GLPI::Agent::Tools::USB::Gertec;

use strict;
use warnings;

use parent qw(GLPI::Agent::Tools::USB);

use GLPI::Agent::Tools;

# Actually supported only on MSWin32
sub enabled {
    return OSNAME eq 'MSWin32';
}

sub supported {
    my ($self) = @_;

    return $self->vendorid =~ /^1753$/i;
}

sub update {
    my ($self) = @_;

    my $serial;

    # TODO Implement serialnumber discovery in registry

    $self->serial($serial)
        unless empty($serial);
}

1;
