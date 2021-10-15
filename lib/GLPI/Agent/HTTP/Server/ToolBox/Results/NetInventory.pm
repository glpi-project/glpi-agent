package GLPI::Agent::HTTP::Server::ToolBox::Results::NetInventory;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox::Results::Fields";

use Memoize;

memoize('__sortable_by_ip');

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless $self, $class;

    return $self;
}

sub order { 21 }

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
        from    => "NAME",
        text    => "Device name or IP",
        column  => 0,
        editcol => 0,
        index   => 0, # Used to order field in edit mode and in a given edit column
    },
    {
        name    => "ip",
        section => "network",
        type    => "readonly",
        from    => "IP",
        text    => "IP",
        column  => 1,
        editcol => 0,
        index   => 1,
    },
    {
        name    => "ips",
        section => "network",
        type    => "readonly",
        text    => "IPs",
        column  => 9,
        editcol => 0,
        index   => 2,
    },
    {
        name    => "mac",
        section => "network",
        type    => "readonly",
        from    => "MAC",
        text    => "MAC",
        column  => 1,
        editcol => 1,
        index   => 2,
    },
    {
        name    => "serial",
        section => "default",
        type    => "readonly",
        from    => "SERIAL",
        text    => "SerialNumber",
        column  => 4,
        editcol => 1,
        index   => 1,
    },
    {
        name    => "description",
        section => "default",
        type    => "readonly",
        from    => "COMMENTS",
        text    => "Description",
        column  => 100,
        editcol => 0,
        index   => 10,
    },
    {
        name    => "location",
        section => "default",
        type    => "readonly",
        from    => "LOCATION",
        text    => "Location",
        column  => 10,
        editcol => 0,
        index   => 6,
    },
    {
        name    => "type",
        section => "default",
        type    => "readonly",
        from    => "TYPE",
        text    => "Type",
        column  => 1,
        editcol => 1,
        index   => 0,
    },
    {
        name    => "contact",
        section => "default",
        type    => "readonly",
        from    => "CONTACT",
        text    => "Contact",
        column  => 1,
        editcol => 1,
        index   => 30,
    },
    {
        name    => "manufacturer",
        section => "default",
        type    => "readonly",
        from    => "MANUFACTURER",
        text    => "Manufacturer",
        column  => 5,
        editcol => 0,
        index   => 5,
    },
    {
        name    => "model",
        section => "default",
        type    => "readonly",
        from    => "MODEL",
        text    => "Model",
        column  => 4,
        editcol => 0,
        index   => 4,
    },
    {
        name    => "tag",
        section => "default",
        type    => "readonly",
        text    => "Tag",
        column  => 20,
        editcol => 0,
        index   => 20,
        noedit  => 1,
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
    my ($self, $name, $tree, $file) = @_;

    return unless $name && $tree;

    my $query = $tree && $tree->{REQUEST} && $tree->{REQUEST}->{QUERY}
        or return;

    return unless $query =~ /^SNMPQUERY$/;

    my $infos = $tree->{REQUEST}->{CONTENT} && $tree->{REQUEST}->{CONTENT}->{DEVICE}
        && $tree->{REQUEST}->{CONTENT}->{DEVICE}->{INFO}
        or return;

    my $fields = $self->fields_common_analysis($infos);

    if ($infos->{IPS} && $infos->{IPS}->{IP}) {
        my $ips = $infos->{IPS}->{IP};
        $fields->{ips} = ref($ips) ? join(",",@{$ips}) : $ips;
        $fields->{ip} = $name if ! $fields->{ip} &&
            ref($ips) ? grep { /^$name$/ } @{$ips} : $ips eq $name ;
    }

    # Extract tag from file name
    my ($tag) = $file =~ m|/\d+\.\d+\.\d+\.\d+_(.+)\.xml$|;
    $fields->{tag}    = $tag || '';

    # Set source
    my $source = $self->name;
    $source = 'Edition'
        if ($tree->{REQUEST}->{DEVICEID} && $tree->{REQUEST}->{DEVICEID} eq 'toolbox');
    $fields->{source} = $source;

    # Set noedit for all found values if it was not an Edition
    unless ($source eq 'Edition') {
        map { $fields->{_noedit}->{$_} = 1 } keys(%{$fields});
        # Don't change noedit flag for type if not a known one
        delete $fields->{_noedit}->{type} unless $fields->{type} =~ /^NETWORKING|PRINTER|STORAGE$/;
    }

    return $fields;
}

sub __sortable_by_ip {
    my ($fields) = @_;
    return '' unless $fields && $fields->{ip};
    return $fields->{ip} unless $fields->{ip} =~ /^(\d+\.\d+\.\d+\.\d+)/;
    # encoding ip as hex string make it sortable by cmp comparator
    return join("", map { sprintf("%02X",$_) } split(/\./, $1));
}

sub update_template_hash {
    my ($self, $hash, $devices) = @_;
    $hash->{netscan_inventory_count} = grep { $_->isNetInventory() } values(%{$devices});
}

1;
