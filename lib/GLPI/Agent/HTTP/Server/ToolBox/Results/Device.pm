package GLPI::Agent::HTTP::Server::ToolBox::Results::Device;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;

    # Don't be loaded as a Results source
    return if $params{results};

    my $self = {
        _name       => $params{name},
    };

    bless $self, $class;

    return $self;
}

sub name {
    my ($self) = @_;
    return $self->{_name};
}

sub source {
    my ($self) = @_;
    return $self->{source} || '';
}

sub ip {
    my ($self) = @_;
    return $self->{ip} || '';
}

sub ips {
    my ($self) = @_;
    return $self->{ips} || '';
}

sub tag {
    my ($self) = @_;
    return $self->{tag} || '';
}

sub type {
    my ($self) = @_;
    return $self->{type} || '';
}

sub mac {
    my ($self) = @_;
    return $self->{mac} || '';
}

sub analyse_with {
    my ($self, $any_sources, $type_sources) = @_;

    my %files = map { $_ => 1 } keys(%{$self->{_files}});
    $self->{_used_sources} = {};

    # Sources are ordered to match files in the expected order
    foreach my $source (@{$any_sources}, @{$type_sources}) {
        my @files = keys(%files)
            or last;
        foreach my $file (@files) {
            my $fields = $source->analyze($self->name, $self->{_files}->{$file}, $file)
                or next;
            delete $files{$file} unless $source->any;
            $self->{_active_sources}->{$file} = $source;
            $self->{_used_sources}->{$source->name} = 1;
            $self->set_fields($fields);
            last;
        }
    }
}

sub set_fields {
    my ($self, $fields) = @_;

    foreach my $key (keys(%{$fields})) {
        # Anyway, don't override source if still an Edition
        next if ($key eq 'source' && $self->{_edition});
        if (ref($fields->{$key}) eq 'HASH') {
            # Essentially for noedit feature
            map { $self->{$key}->{$_} = $fields->{$key}->{$_} } keys(%{$fields->{$key}});
        } elsif (defined($fields->{$key}) && length($fields->{$key})) {
            # Merge values in device
            $self->{$key} = $fields->{$key};
        }
    }

    # Has this device been edited with custom fields ?
    $self->{_edition} = 1 if $self->{source} && $self->{source} eq 'Edition';
}

sub set {
    my ($self, $field, $value) = @_;
    $self->{$field} = $value;

    # Defines if this device is an edition
    $self->{_edition} = 1 if ($field && $field eq 'source' && $value && $value eq 'Edition');
}

sub del {
    my ($self, $field) = @_;
    delete $self->{$field};
}

sub get {
    my ($self, $field) = @_;
    return defined($self->{$field}) && length($self->{$field}) ? $self->{$field} : '';
}

sub noedit {
    my ($self, $field) = @_;
    return unless $self->{_noedit};
    return keys(%{$self->{_noedit}}) unless $field;
    # Don't edit if no edition permission has been set for a field
    return !defined($self->{_noedit}->{$field}) || $self->{_noedit}->{$field} ? 1 : 0;
}

sub dontedit {
    my ($self, $field) = @_;
    $self->{_noedit}->{$field} = 1;
}

sub editfield {
    my ($self, $field) = @_;
    $self->{_noedit}->{$field} = 0;
}

sub deduplicate {
    my ($self, $devices) = @_;

    my $found;
    foreach my $device (values(%{$devices})) {
        next if $device == $self;
        next unless $device->ip && $device->ip eq $self->ip;
        #next unless $device->mac && $device->mac eq $self->mac;
        next unless $device->tag eq $self->tag;
        $found = $device;
        last;
    }

    if ($found) {
        # Merge files in current device
        foreach my $xml (keys(%{$found->{_files}})) {
            $self->{_files}->{$xml} = $found->{_files}->{$xml};
        }
    }

    return $found;
}

sub set_xml {
    my ($self, $file, $tree) = @_;

    $self->{_files}->{$file} = $tree;
}

sub getFiles {
    my ($self) = @_;
    return unless $self->{_files};
    return keys(%{$self->{_files}});
}

sub deleted_xml {
    my ($self, $file) = @_;

    delete $self->{_files}->{$file};
    $self->{_active_sources}->{$file}->forget($file)
        if $self->{_active_sources}->{$file};
}

sub isLocalInventory {
    my ($self) = @_;
    return exists($self->{_used_sources}->{Inventory}) ? 1 : 0;
}

sub hasNetScan {
    my ($self) = @_;
    return exists($self->{_used_sources}->{NetDiscovery}) ? 1 : 0;
}

sub isNetInventory {
    my ($self) = @_;
    return exists($self->{_used_sources}->{NetInventory}) ? 1 : 0;
}

1;
