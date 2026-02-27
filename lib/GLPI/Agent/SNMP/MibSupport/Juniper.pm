package GLPI::Agent::SNMP::MibSupport::Juniper;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    enterprises => '.1.3.6.1.4.1' ;

# See JUNIPER-SMI
use constant    juniperMIB      => enterprises . '.2636';
use constant    jnxMIBs         => juniperMIB . '.3';
use constant    jnxExMibRoot    => jnxMIBs . '.40';

# See JUNIPER-EX-SMI
use constant    jnxExVirtualChassis => jnxExMibRoot . '.1.4';

# See JUNIPER-VIRTUALCHASSIS-MIB
use constant    jnxVirtualChassisMemberSerialnumber => jnxExVirtualChassis . '.1.1.1.2';
use constant    jnxVirtualChassisMemberRole         => jnxExVirtualChassis . '.1.1.1.3';
use constant    jnxVirtualChassisMemberMacAddBase   => jnxExVirtualChassis . '.1.1.1.4';
use constant    jnxVirtualChassisMemberSWVersion    => jnxExVirtualChassis . '.1.1.1.5';
use constant    jnxVirtualChassisMemberModel        => jnxExVirtualChassis . '.1.1.1.8';


our $mibSupport = [
    {
        name        => "juniper",
        sysobjectid => getRegexpOidMatch(juniperMIB)
    }
];

sub _getMasterKey {
    my ($self) = @_;

    my $device = $self->device
        or return ".0";

    # Return cached value for this device
    return $device->{_master} if defined($device->{_master});

    my $role = $self->walk(jnxVirtualChassisMemberRole)
        or return ".0";

    my $index = first { isInteger($role->{$_}) && $role->{$_} == 1 } keys(%{$role});
    return $device->{_master} = empty($index) ? ".0" : ".$index";
}

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(jnxVirtualChassisMemberSWVersion.$self->_getMasterKey()));
}

sub getMacAddress {
    my ($self) = @_;

    return getCanonicalMacAddress($self->get(jnxVirtualChassisMemberMacAddBase.$self->_getMasterKey()));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(jnxVirtualChassisMemberModel.$self->_getMasterKey()));
}

sub getSerial {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{SERIAL};

    return getCanonicalString($self->get(jnxVirtualChassisMemberSerialnumber.$self->_getMasterKey()));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    if ($device->{PORTS} && ref($device->{PORTS}->{PORT}) eq 'HASH') {

        # Index ports by IFNAME
        my %index;
        my $ports = $device->{PORTS}->{PORT};
        my @portnames = sortedPorts($ports);
        foreach my $index (@portnames) {
            next if empty($ports->{$index}->{IFNAME});
            $index{$ports->{$index}->{IFNAME}} = $index;
        }

        # Search virtualport on which physical port should be merged to handle
        # connections as expected in GLPI
        foreach my $name (@portnames) {
            my $port = $ports->{$name};
            next unless $port->{IFTYPE} && isInteger($port->{IFTYPE}) && int($port->{IFTYPE}) == 53;
            my ($physical) = $port->{IFNAME} =~ /^(.+)\.\d+$/
                or next;
            next unless $ports->{$index{$physical}};
            next unless $port->{MAC} && $ports->{$index{$physical}}->{MAC} && $port->{MAC} eq $ports->{$index{$physical}}->{MAC};
            next unless $port->{IFMTU} && $ports->{$index{$physical}}->{IFMTU} && $port->{IFMTU} eq $ports->{$index{$physical}}->{IFMTU};
            my $merge = delete $ports->{$index{$physical}};
            map {
                $port->{$_} = $merge->{$_} if $merge->{$_}
            } qw( IFNAME IFDESCR IFTYPE IFSPEED VLAN CONNECTIONS );
            map {
                $port->{$_} = 0 unless $port->{$_};
                $port->{$_} += $merge->{$_} if $merge->{$_};
            } qw( IFINERRORS IFINOCTETS IFOUTERRORS IFOUTOCTETS );
        }
    }

    # Update components if necessary
    if ($device->{COMPONENTS} && ref($device->{COMPONENTS}->{COMPONENT}) eq 'ARRAY') {
        my $components = $device->{COMPONENTS}->{COMPONENT};

        my $model = $self->walk(jnxVirtualChassisMemberModel);
        my $serial = $self->walk(jnxVirtualChassisMemberSerialnumber);

        # List chassis, container and module components
        my @chassis   = grep { $_->{TYPE} && $_->{TYPE} eq 'chassis'   } @{$components};
        my @container = grep { $_->{TYPE} && $_->{TYPE} eq 'container' } @{$components};

        if (@container > 1) {
            # First rename "chassis" as "virtualchassis" when containers also exists
            map { $_->{TYPE} = 'virtualchassis' } @chassis;

            # Then copy parent module container values
            foreach my $container (@container) {
                next unless $container->{SERIAL};
                my $key = first { $serial->{$_} && getCanonicalString($serial->{$_}) eq $container->{SERIAL} } keys(%{$serial});
                $container->{MODEL} = getCanonicalString($model->{$key}) if defined($key) && $model->{$key};
                # Finally change container type to chassis
                $container->{TYPE} = "chassis";
            }
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Juniper - Inventory module to fix Juniper connections

=head1 DESCRIPTION

The module enhances Juniper support.
