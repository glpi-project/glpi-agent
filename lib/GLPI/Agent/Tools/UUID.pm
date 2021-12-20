package GLPI::Agent::Tools::UUID;

use strict;
use warnings;

use parent 'Exporter';

use Data::UUID;

our @EXPORT = qw(
    create_uuid
    create_uuid_from_name
    is_uuid_string
    uuid_to_string
);

# Imported from UUID::Tiny
my $IS_UUID_STRING = qr/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/is;

sub create_uuid {
    my $uuid = Data::UUID->new();
    return $uuid->create();
}

sub create_uuid_from_name {
    my ($name) = @_;
    my $uuid = Data::UUID->new();
    return $uuid->create_from_name_str(NameSpace_DNS, $name);
}

sub uuid_to_string {
    my ($uuid) = @_;
    return '' unless defined($uuid);
    my $uuidlib = Data::UUID->new();
    return lc($uuidlib->to_string($uuid));
}

sub is_uuid_string {
    my ($uuid) = @_;
    return defined($uuid) && $uuid =~ $IS_UUID_STRING;
}

1;
