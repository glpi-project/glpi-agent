package GLPI::Agent::HTTP::Server::ToolBox::Results::Inventory;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox::Results::Fields";

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless $self, $class;

    return $self;
}

sub order { 22 }

sub sections {
    return {
        name    => "default",
        index   => 0, # section index, lowest is show first
        #title   => "Device", # No section title will be shown if title is not set
    },
    {
        name    => "network",
        index   => 1,
        title   => "Networking"
    };
}

sub fields {
    my ($self) = @_;

    return {
        name    => "name",
        section => "default",
        type    => "readonly",
        from    => [ qw(NAME DNS) ], # First giving a value is used
        text    => "Device name or IP",
        column  => 0,
        editcol => 0,
        index   => 0, # Used to order field in edit mode and in a given edit column
        tag     => "HARDWARE",
    },
    {
        name    => "uuid",
        section => "default",
        type    => "readonly",
        from    => "UUID",
        text    => "UUID",
        column  => 1,
        editcol => 1,
        index   => 3,
        tag     => "HARDWARE",
    },
    {
        name    => "serial",
        section => "default",
        type    => "readonly",
        from    => "SSN",
        text    => "SerialNumber",
        column  => 4,
        editcol => 1,
        index   => 0,
        tag     => "BIOS",
    },
    {
        name    => "osname",
        section => "default",
        type    => "readonly",
        from    => "FULL_NAME",
        text    => "OS Name",
        column  => 10,
        editcol => 1,
        index   => 4,
        tag     => "OPERATINGSYSTEM",
    },
    {
        name    => "manufacturer",
        section => "default",
        type    => "readonly",
        from    => "SMANUFACTURER",
        text    => "Manufacturer",
        column  => 5,
        editcol => 0,
        index   => 5,
        tag     => "BIOS",
    },
    {
        name    => "model",
        section => "default",
        type    => "readonly",
        from    => "SMODEL",
        text    => "Model",
        column  => 4,
        editcol => 0,
        index   => 4,
        tag     => "BIOS",
    },
    {
        name    => "type",
        section => "default",
        type    => "readonly",
        text    => "Type",
        column  => 1,
        editcol => 1,
        index   => 0,
    },
    {
        name    => "tag",
        section => "default",
        type    => "readonly",
        text    => "Tag",
        column  => 20,
        editcol => 0,
        index   => 20,
    },
    {
        name    => "source",
        section => "default",
        type    => "readonly",
        text    => "Source",
        column  => 21,
        editcol => 1,
        index   => 21,
    };
}

sub analyze {
    my ($self, $name, $tree) = @_;

    return unless $name && $tree;

    my $query = $tree && $tree->{REQUEST} && $tree->{REQUEST}->{QUERY}
        or return;

    return unless $query =~ /^INVENTORY$/;

    my $dev = $tree->{REQUEST}->{CONTENT}
        or return;

    my $device = $self->fields_common_analysis($dev);

    $device->{ip} = $1
        if $device->{ips} && $device->{ips} =~ /^(\d+\.\d+\.\d+\.\d+)/;

    # Get deviceid for deduplication
    $device->{deviceid} = $tree->{REQUEST}->{DEVICEID};

    # Get MAC from NETWORKS ports
    if ($dev->{NETWORKS}) {
        my @network_ports = ref($dev->{NETWORKS}) eq 'ARRAY' ? @{$dev->{NETWORKS}} : ($dev->{NETWORKS});
        @network_ports = grep { !$_->{VIRTUALDEV} && $_->{MACADDR} && $_->{MACADDR} ne '00:00:00:00:00:00' } @network_ports;
        if ($device->{ip}) {
            my ($network_port) = grep {
                $_->{IPADDRESS} && $_->{IPADDRESS} eq $device->{ip}
            } @network_ports;
            $device->{mac} = $network_port->{MACADDR};
        }
        # Also set all network cards MAC so we can match netscan device on MAC
        my @ports = grep { $_->{IPADDRESS} || $_->{IPADDRESS6} } @network_ports;
        my %macs = (
            map { $_->{MACADDR} => $_->{IPADDRESS} // $_->{IPADDRESS6} } @ports
        );
        $device->{macs} = [ keys(%macs) ];
        if (!$device->{ip} || !$device->{ips}) {
            my %mac_by_ip = map { ($_->{IPADDRESS} // $_->{IPADDRESS6}) => $_->{MACADDR} } @ports;
            my @ips = map { $_->{IPADDRESS} || $_->{IPADDRESS6} } @ports;
            $device->{ip} = $ips[0] unless $device->{ip};
            $device->{mac} = $mac_by_ip{$device->{ip}}
                unless $device->{mac} || !$device->{ip};
            # Set ips if still not set
            $device->{ips} = join(',', @ips)
                unless $device->{ips};
        }
    }

    $device->{type} = "COMPUTER";
    $device->{source} = "Local";
    if ($dev->{ACCOUNTINFO} && $dev->{ACCOUNTINFO}->{KEYNAME} && $dev->{ACCOUNTINFO}->{KEYNAME} eq 'TAG') {
        $device->{tag} = $dev->{ACCOUNTINFO}->{KEYVALUE};
    } else {
        # For local source, only included tag is mandatory even if we seen it during netscan
        $device->{tag} = '';
    }

    # Don't permit any standard fields edition
    my @netinventory_fields = GLPI::Agent::HTTP::Server::ToolBox::Results::NetInventory->fields();
    $device->{_noedit} = { map { $_->{name} => 1 } $self->fields(), @netinventory_fields };

    return $device;
}

sub update_template_hash {
    my ($self, $hash, $devices) = @_;
    $hash->{local_inventory_count} = grep { $_->isLocalInventory() } values(%{$devices});
}

1;
