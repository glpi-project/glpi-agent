package GLPI::Agent::SOAP::WsMan::OperationID;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    OperationID;

use parent
    'Node';

use Data::UUID;

use constant    xmlns   => 'p';

use GLPI::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $operationid) = @_;

    return $class->SUPER::new($operationid) if $operationid;

    my $uuid_gen = Data::UUID->new();
    my $uuid = $uuid_gen->create_str();

    my $self = $class->SUPER::new(
        Attribute->must_understand("false"),
        "uuid:$uuid",
    );

    $self->{_uuid} = $uuid;

    bless $self, $class;
    return $self;
}

sub uuid {
    my ($self) = @_;

    my ($uuid) = $self->string =~ /^uuid:(.*)$/;

    return unless $self->{_uuid} || $uuid;

    return $self->{_uuid} if $self->{_uuid};

    return $self->{_uuid} = $uuid;
}

sub reset_uuid {
    my ($self) = @_;
    my $uuid_gen = Data::UUID->new();
    my $uuid = $uuid_gen->create_str();

    $self->{_uuid} = $uuid;

    return $self->string("uuid:$uuid");
}

sub equals {
    my ($self, $other) = @_;

    return 0 unless $other;

    my $uuid_gen = Data::UUID->new();

    return $self->uuid eq $other->uuid;
}

1;
