package GLPI::Agent::SNMP::MibSupport::NetApp;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See NETAPP-MIB

use constant    netapp  => '.1.3.6.1.4.1.789' ;

use constant    storage => netapp . '.1.21' ;
use constant    network => netapp . '.1.22' ;
use constant    cluster => netapp . '.1.25' ;

use constant    netappCluster   => netapp . '.2.5' ;

use constant    logicalInterfaceEntry   => network . '.4.1';
use constant    logicalInterfaceRole        => logicalInterfaceEntry . '.3';
use constant    logicalInterfaceCurrNode    => logicalInterfaceEntry . '.6';
use constant    logicalInterfaceAddress     => logicalInterfaceEntry . '.11';

use constant    clusterIdentityUuid => cluster . '.1.1.0';
use constant    clusterIdentityName => cluster . '.1.2.0';

use constant    nodeEntry   => cluster . '.2.1';

use constant    nodeName            => nodeEntry . '.1';
use constant    nodeModel           => nodeEntry . '.4';
use constant    nodeSerialNumber    => nodeEntry . '.5';
use constant    nodeVendor          => nodeEntry . '.10';
use constant    nodeUuid            => nodeEntry . '.14';
use constant    nodeProductVersion  => nodeEntry . '.23';
use constant    nodeFirmwareVersion => nodeEntry . '.24';

use constant    enclEntry   => storage . '.1.2.1';

use constant    enclProductLogicalID        => enclEntry . '.4.1';
use constant    enclProductVendor           => enclEntry . '.6.1';
use constant    enclProductModel            => enclEntry . '.7.1';

our $mibSupport = [
    {
        name        => "netapp-cluster",
        sysobjectid => getRegexpOidMatch(netappCluster)
    }
];

sub _getNode {
    my ($self) = @_;

    return $self->{_node} if defined($self->{_node});

    my $node = $self->{_node} = {};

    my $role = $self->walk(logicalInterfaceRole)
        or return;

    my $address = $self->walk(logicalInterfaceAddress)
        or return;

    my $device = $self->device
        or return;

    # Get the ip from session hostname to identify if cluster or peer is contacted
    my $ip = $device->{snmp}->peer_address() // '';

    # ip has to be registered on the device
    my $key = first { !empty($address->{$_}) && $address->{$_} eq $ip } keys(%{$address});
    return if empty($key);

    # Role should be cluster-mgmt (5) or node-mgmt (3)
    return if empty($role->{$key}) || $role->{$key} !~ /^3|5$/;

    # Analyze current node if not the cluster
    if (int($role->{$key}) == 3) {
        my $uuid = getCanonicalString($self->get(logicalInterfaceCurrNode.'.'.$key))
            or return;

        my $nodeuuid = $self->walk(nodeUuid)
            or return;

        # Get cluster node key
        my $nodekey = first { getCanonicalString($nodeuuid->{$_}) eq $uuid } keys(%{$nodeuuid})
            or return;

        my %mapping = (
            name        => nodeName,
            model       => nodeModel,
            serial      => nodeSerialNumber,
            vendor      => nodeVendor,
            version     => nodeProductVersion,
            firmware    => nodeFirmwareVersion,
        );

        foreach my $key (keys(%mapping)) {
            my $value = getCanonicalString($self->get($mapping{$key}.'.'.$nodekey));
            $node->{$key} = $value
                unless empty($value);
        }
    } else {
        # Prepare a node for the cluster
        $node->{name} = getCanonicalString($self->get(clusterIdentityName));
        $node->{serial} = getCanonicalString($self->get(clusterIdentityUuid) // $self->get(enclProductLogicalID));
        $node->{vendor} = getCanonicalString($self->get(enclProductVendor));
        $node->{model} = getCanonicalString($self->get(enclProductModel));
    }

    return $node;
}

sub getFirmware {
    my ($self) = @_;

    my $node = $self->_getNode()
        or return;

    return $node->{firmware};
}

sub getModel {
    my ($self) = @_;

    my $node = $self->_getNode()
        or return;

    return $node->{model};
}

sub getSerial {
    my ($self) = @_;

    my $node = $self->_getNode()
        or return;

    return $node->{serial};
}

sub getSnmpHostname {
    my ($self) = @_;

    my $node = $self->_getNode()
        or return;

    return $node->{name};
}

sub getType {
    return "STORAGE";
}

sub getVendor {
    my ($self) = @_;

    my $node = $self->_getNode()
        or return;

    return $node->{vendor};
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $node = $self->_getNode()
        or return;

    return if empty($node->{version});

    my $model = $device->{MODEL} ? $device->{MODEL}." " : "";
    my $firmware = {
        NAME            => $model."version",
        DESCRIPTION     => "software version",
        TYPE            => "device",
        VERSION         => $node->{version},
        MANUFACTURER    => "NetApp"
    };

    $device->addFirmware($firmware);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::NetApp - Inventory module for NetApp devices

=head1 DESCRIPTION

The module enhances NetApp device support.
