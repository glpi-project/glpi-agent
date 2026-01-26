package GLPI::Agent::Tools::USB::HP;

use strict;
use warnings;

use parent qw(GLPI::Agent::Tools::USB);

use UNIVERSAL::require;

use GLPI::Agent::Tools;

# Actually supported only on MSWin32
sub enabled {
    return OSNAME eq 'MSWin32';
}

sub supported {
    my ($self) = @_;

    return $self->vendorid =~ /^03F0$/i;
}

sub update {
    my ($self) = @_;

    return if empty($self->{_name});

    GLPI::Agent::Tools::Win32->require();

    # Try to get serial from dedicated WMI Object
    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
        class      => 'HP_DockAccessory',
        moniker    => 'winmgmts://./root/HP/InstrumentedServices/v1',
        properties => [ qw/ProductName SerialNumber/ ]
    )) {
        next if empty($object->{ProductName}) || empty($object->{SerialNumber});

        next unless $object->{ProductName} =~ /$self->{_name}$/i;

        $self->serial($object->{SerialNumber});
    }
}

1;
