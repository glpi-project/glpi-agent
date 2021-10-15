package GLPI::Agent::SOAP::WsMan::MessageID;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    MessageID;

use parent
    'Node';

use Data::UUID;

use constant    xmlns   => 'a';

sub new {
    my ($class, $messageid) = @_;

    return $class->SUPER::new($messageid) if $messageid;

    my $uuid_gen = Data::UUID->new();
    my $uuid = $uuid_gen->create_str();

    my $self = $class->SUPER::new("uuid:$uuid");

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

1;
