package FusionInventory::Agent::SOAP::WsMan::SessionId;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    SessionId;

use parent 'Node';

use Data::UUID;

use constant    xmlns   => 'p';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, %params) = @_;

    return $class->SUPER::new(%params) if %params;

    my $uuid_gen = Data::UUID->new();
    my $uuid = $uuid_gen->create_str();

    my $self = $class->SUPER::new(
        Attribute->must_understand("false"),
        '#text' => "uuid:$uuid",
    );

    $self->{_uuid} = $uuid;

    bless $self, $class;
    return $self;
}

sub uuid {
    my ($self) = @_;

    return $self->{_uuid} if $self->{_uuid};
}

1;
