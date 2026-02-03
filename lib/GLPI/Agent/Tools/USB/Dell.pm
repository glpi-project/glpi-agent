package GLPI::Agent::Tools::USB::Dell;

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

    return $self->vendorid =~ /^413C$/i && $self->productid =~ /^B06E$/i;
}

sub update {
    my ($self) = @_;

    GLPI::Agent::Tools::Win32->require();

    # Try to get serial from dedicated WMI Object
    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
        class      => 'DCIM_Chassis',
        moniker    => 'winmgmts://./root/dcim/sysman',
        properties => [ qw/ChassisPackageType ChassisTypeDescription Name SerialNumber/ ]
    )) {
        next if empty($object->{ChassisPackageType}) || empty($object->{ChassisTypeDescription}) || empty($object->{Name}) || empty($object->{SerialNumber});

        next unless $object->{ChassisPackageType} =~ /$\d+$/ && $object->{ChassisPackageType} == 12;

        $self->serial($object->{SerialNumber});
        $self->{_name} = $object->{Name}." ".$object->{ChassisTypeDescription};
        last;
    }
}

1;
