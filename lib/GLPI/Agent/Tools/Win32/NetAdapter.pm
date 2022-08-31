package GLPI::Agent::Tools::Win32::NetAdapter;

use warnings;
use strict;

use English qw(-no_match_vars);

use GLPI::Agent::Tools::Network;

sub new {
    my ($class, %params) = @_;

    return unless defined $params{WMI} && defined $params{configurations};

    my $self = { %{$params{WMI}} };
    bless $self, $class;

    $self->{_config} = $params{configurations}[$self->_getObjectIndex()]
        or return;

    return unless $self->_getPNPDeviceID();

    return $self;
}

sub getInterfaces {
    my ($self) = @_;

    return $self->getInterfacesWithAddresses() if $self->hasAddresses();

    return unless $self->{_config}->{MACADDR};

    return $self->getBaseInterface();
}

sub getBaseInterface {
    my ($self) = @_;

    my $interface = {
        PNPDEVICEID => $self->_getPNPDeviceID(),
        MACADDR     => $self->{_config}->{MACADDR},
        DESCRIPTION => $self->_getDescription(),
        STATUS      => $self->{_config}->{STATUS},
        MTU         => $self->{_config}->{MTU},
        dns         => $self->{_config}->{dns},
        VIRTUALDEV  => $self->_isVirtual()
    };

    $interface->{PCIID}     = $self->_getPciid() if $self->_getPciid();
    $interface->{GUID}      = $self->_getGUID() if $self->_getGUID();
    $interface->{DNSDomain} = $self->{_config}->{DNSDomain} if $self->{_config}->{DNSDomain};
    $interface->{SPEED}     = int($self->{Speed} / 1_000_000) if $self->{Speed};

    if ($self->{InterfaceType}) {
        # Interface type as defined by the Internet Assigned Names Authority (IANA)
        # Same list as default GLPI supported types
        my %types = qw(
            6   ethernet
            7   ethernet
            56  fiberchannel
            62  ethernet
            71  wifi
            117 ethernet
            169 ethernet
        );
        $interface->{TYPE} = $types{$self->{InterfaceType}}
            if $types{$self->{InterfaceType}};
    }

    return $interface;
}

sub getInterfacesWithAddresses {
    my ($self) = @_;

    my @interfaces;

    foreach my $address (@{$self->{_config}->{addresses}}) {
        my $interface = $self->getBaseInterface();
        if ($address->[0] =~ /$ip_address_pattern/) {
            $interface->{IPADDRESS} = $address->[0];
            $interface->{IPMASK}    = $address->[1];
            $interface->{IPSUBNET}  = getSubnetAddress(
                $interface->{IPADDRESS},
                $interface->{IPMASK}
            );
            $interface->{IPDHCP}        = $self->{_config}->{IPDHCP};
            $interface->{IPGATEWAY}     = $self->{_config}->{IPGATEWAY};
        } else {
            $interface->{IPADDRESS6}    = $address->[0];
            $interface->{IPMASK6}       = getNetworkMaskIPv6($address->[1]);
            $interface->{IPSUBNET6}     = getSubnetAddressIPv6(
                $interface->{IPADDRESS6},
                $interface->{IPMASK6}
            );
        }
        push @interfaces, $interface;
    }

    return @interfaces;
}

sub hasAddresses {
    my ($self) = @_;

    return $self->{_config}->{addresses} ? 1 : 0;
}

sub _isVirtual {
    my ($self) = @_;

    # Some virtual network adapters like VirtualBox or VPN ones could be set
    # as physical but with PNPDeviceID starting by ROOT
    return 1 if $self->_getPNPDeviceID() =~ /^ROOT/;

    # PhysicalAdapter only work on OS > XP
    my $physical = $self->{HardwareInterface} || $self->{PhysicalAdapter};
    return $physical =~ /^1|true/i ? 0 : 1 if defined($physical);

    # http://forge.fusioninventory.org/issues/1166
    my $description = $self->_getDescription();
    return 1 if $description && $description =~ /RAS/ && $description =~ /Adapter/i;

    return 0;
}

sub _getPciid {
    my ($self) = @_;

    return unless $self->_getPNPDeviceID() =~ /PCI\\VEN_(\w{4})&DEV_(\w{4})&SUBSYS_(\w{4})(\w{4})/;

    return join(':', $1, $2, $3, $4);
}

sub _getObjectIndex {
    my ($self) = @_;

    return defined($self->{InterfaceIndex}) ? $self->{InterfaceIndex} : $self->{Index};
}

# Getters try get Information on MSFT_NetAdapter || Win32_NetworkAdapter

sub _getGUID {
    my ($self) = @_;

    return $self->{InterfaceGuid} || $self->{GUID};
}

sub _getPNPDeviceID {
    my ($self) = @_;

    return $self->{PnPDeviceID} || $self->{PNPDeviceID};
}

sub _getDescription {
    my ($self) = @_;

    return $self->{InterfaceDescription} || $self->{_config}->{DESCRIPTION};
}

1;
