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

    return unless $self->{_config}->{MACADDR} || $self->_getHardwareDescription() =~ /vpn/i;

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

    $interface->{MANUFACTURER} = $self->_getManufacturer() if $self->_getManufacturer();
    $interface->{MODEL}        = $self->_getModel()        if $self->_getModel();
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
            # Remove any win32 scope IP from local IPv6 address
            $interface->{IPADDRESS6} =~ s/%\d+$//;
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
    my $hwDescription = $self->_getHardwareDescription();
    return 1 if $hwDescription && $hwDescription =~ /RAS/ && $hwDescription =~ /Adapter/i;

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

sub _getManufacturer {
    my ($self) = @_;

    # MSFT_NetAdapter (Win8+) exposes DriverProvider as the manufacturer
    return $self->{DriverProvider} if $self->{DriverProvider};

    # Win32_NetworkAdapter (legacy) has Manufacturer
    return $self->{Manufacturer} if $self->{Manufacturer};

    return;
}

sub _getModel {
    my ($self) = @_;

    # MSFT_NetAdapter (Win8+) exposes DriverDescription as the model name
    return $self->{DriverDescription} if $self->{DriverDescription};

    # Win32_NetworkAdapter (legacy) has Name which reflects the adapter model
    return $self->{Name} if $self->{Name};

    return;
}

sub _getGUID {
    my ($self) = @_;

    return $self->{InterfaceGuid} || $self->{GUID};
}

sub _getPNPDeviceID {
    my ($self) = @_;

    return $self->{PnPDeviceID} || $self->{PNPDeviceID};
}

sub _getHardwareDescription {
    my ($self) = @_;

    return $self->{InterfaceDescription} || $self->{_config}->{DESCRIPTION};
}

sub _getConnectionName {
    my ($self) = @_;

    # MSFT_NetAdapter (Win8+) exposes Name as the connection name
    return $self->{Name} if $self->{InterfaceDescription} && $self->{Name};

    # Win32_NetworkAdapter (legacy) exposes NetConnectionID
    return $self->{NetConnectionID} if $self->{NetConnectionID};

    return;
}

sub _getDescription {
    my ($self) = @_;

    my $connectionName = $self->_getConnectionName();
    return $connectionName if $connectionName;

    return $self->_getHardwareDescription();
}

1;
