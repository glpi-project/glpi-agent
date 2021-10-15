package GLPI::Agent::SOAP::WsMan::SessionId;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    SessionId;

use parent
    'Node';

use Data::UUID;

use constant    xmlns   => 'p';

use GLPI::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $sessionid) = @_;

    return $class->SUPER::new($sessionid) if $sessionid;

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

1;
